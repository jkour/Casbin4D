// Copyright 2018 The Casbin Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
unit Casbin;

interface

uses
  Casbin.Core.Base.Types, Casbin.Types, Casbin.Model.Types,
  Casbin.Policy.Types, Casbin.Adapter.Types, Casbin.Core.Logger.Types;

type
  TCasbin = class (TBaseInterfacedObject, ICasbin)
  private
    fModel: IModel;
    fPolicy: IPolicyManager;
    fLogger: ILogger;
    fEnabled: boolean;
  private
{$REGION 'Interface'}
    function getModel: IModel;
    function getPolicy: IPolicyManager;
    procedure setModel(const aValue: IModel);
    procedure setPolicy(const aValue: IPolicyManager);
    function getLogger: ILogger;
    procedure setLogger(const aValue: ILogger);
    function getEnabled: Boolean;
    procedure setEnabled(const aValue: Boolean);

    function enforce (const aParams: TEnforceParameters): boolean;
{$ENDREGION}
  public
    constructor Create; overload;
    constructor Create(const aModelFile, aPolicyFile: string); overload;  //PALOFF
    constructor Create(const aModel: IModel; const aPolicyAdapter: IPolicyManager);
        overload;
  end;

implementation

uses
  Casbin.Exception.Types, Casbin.Model, Casbin.Policy,
  Casbin.Core.Logger.Default, System.Generics.Collections, System.SysUtils,
  Casbin.Resolve, Casbin.Resolve.Types, Casbin.Model.Sections.Types,
  Casbin.Core.Utilities, System.Rtti, Casbin.Effect.Types, Casbin.Effect,
  Casbin.Functions.Types, Casbin.Functions, Casbin.Adapter.Memory, Casbin.Adapter.Memory.Policy, System.SyncObjs;

var
  criticalSection: TCriticalSection;

constructor TCasbin.Create(const aModelFile, aPolicyFile: string);
begin
  Create(TModel.Create(aModelFile), TPolicyManager.Create(aPolicyFile));
end;

constructor TCasbin.Create(const aModel: IModel; const aPolicyAdapter:
    IPolicyManager);
begin
  if not Assigned(aModel) then
    raise ECasbinException.Create('Model Adapter is nil');
  if not Assigned(aPolicyAdapter) then
    raise ECasbinException.Create('Policy Manager is nil');
  inherited Create;
  fModel:=aModel;
  fPolicy:=aPolicyAdapter;
  fLogger:=TDefaultLogger.Create;
  fEnabled:=True;
end;

constructor TCasbin.Create;
begin
  Create(TModel.Create(TMemoryAdapter.Create), TPolicyManager.Create(
                                                  TPolicyMemoryAdapter.Create));
end;

function TCasbin.enforce(const aParams: TEnforceParameters): boolean;
var
  item: string;
  request: TList<string>;
  tmpList: TList<string>;
  requestDict: TDictionary<string, string>;
  policyDict: TDictionary<string, string>;
  requestStr: string;
  matcherResult: TEffectResult;
  matcher: TList<string>;
  policyList: TList<string>;
  policyArray: TArray<string>;
  policy: string;
  effectArray: TEffectArray;
  matchString: string;
  reqDefinitions: TList<string>;
  polDefinitions: TList<string>;
begin
  result:=true;
  if Length(aParams) = 0 then
    Exit;
  if not fEnabled then
    Exit;

  criticalSection.Acquire;
  try
    request:=TList<string>.Create;  //PALOFF
    for item in aParams do
      request.Add(item);

    for item in aParams do
      requestStr:=requestStr+item+',';
    if requestStr[findEndPos(requestStr)]=',' then
      requestStr:=Copy(requestStr, findStartPos,
                          findEndPos(requestStr));

    fLogger.log('Enforcing request '''+requestStr+'''');

    fLogger.log('   Resolving Request...');
    // Resolve Request
  {$IFDEF DEBUG}
    fLogger.log('   Request: '+requestStr);
    tmpList:=fModel.assertions(stRequestDefinition);
    fLogger.log('      Assertions: ');
    if tmpList.Count=0 then
      fLogger.log('         No Request Assertions found')
    else
      for item in tmpList do
        fLogger.log('         '+item);
    tmpList.Free;
  {$ENDIF}
    reqDefinitions:=fModel.assertions(stRequestDefinition);
    requestDict:=resolve(request, rtRequest, reqDefinitions);

    fLogger.log('   Resolving Policies...');

  {$IFDEF DEBUG}
    fLogger.log('   Policies: ');
    fLogger.log('      Assertions: ');
    tmpList:=fPolicy.policies;
    if tmpList.Count=0 then
      fLogger.log('         No Policy Assertions found')
    else
      for item in tmpList do
        fLogger.log('         '+item);

    tmpList:=fModel.assertions(stPolicyDefinition);
    fLogger.log('      Assertions: '+requestStr);
    for item in tmpList do
      fLogger.log('         '+item);
    tmpList.Free;
  {$ENDIF}

    matcher:=fModel.assertions(stMatchers);
  {$IFDEF DEBUG}
    fLogger.log('   Matchers: '+requestStr);
    fLogger.log('      Assertions: ');
    if matcher.Count=0 then
      fLogger.log('         No Matcher Assertions found')
    else
      for item in matcher do
        fLogger.log('         '+item);
  {$ENDIF}
    if matcher.Count>0 then
      matchString:=matcher.Items[0]
    else
      matchString:='';
    for item in fPolicy.policies do
    begin
      // Resolve Policy
      policyList:=TList<string>.Create;   //PALOFF
      policyList.AddRange(item.Split([',']));

      //Item 0 has p,g, etc
      policyList.Delete(0);
      polDefinitions:= fModel.assertions(stPolicyDefinition);
      policyDict:=resolve(policyList, rtPolicy, polDefinitions);

      fLogger.log('   Resolving Functions and Matcher...');
      // Resolve Matcher
      if matchString<>'' then
        matcherResult:=resolve(requestDict, policyDict, TFunctions.Create, matchString)
      else
        matcherResult:=erIndeterminate;
      SetLength(effectArray, Length(effectArray)+1);
      effectArray[Length(effectArray)-1]:=matcherResult; //PALOFF

      polDefinitions.Free;
      policyDict.Free;
      policyList.Free;

    end;
    matcher.Free;

    //Resolve Effector
    fLogger.log('   Merging effects...');

    Result:=mergeEffects(fModel.effectCondition, effectArray);

    fLogger.log('Enforcement completed (Result: '+BoolToStr(Result, true)+')');

    reqDefinitions.Free;
    request.Free;
    requestDict.Free;

  finally
    criticalSection.Release;
  end;
end;

{ TCasbin }

function TCasbin.getEnabled: Boolean;
begin
  Result:=fEnabled;
end;

function TCasbin.getLogger: ILogger;
begin
  Result:=fLogger;
end;

function TCasbin.getModel: IModel;
begin
  Result:=fModel;
end;

function TCasbin.getPolicy: IPolicyManager;
begin
  Result:=fPolicy;
end;

procedure TCasbin.setEnabled(const aValue: Boolean);
begin
  fEnabled:=aValue;
end;

procedure TCasbin.setLogger(const aValue: ILogger);
begin
  if Assigned(aValue) then
  begin
    fLogger:=nil;
    fLogger:=aValue;
  end;
end;

procedure TCasbin.setModel(const aValue: IModel);
begin
  if not Assigned(aValue) then
    raise ECasbinException.Create('Model in nil');
  fModel:=aValue;
end;

procedure TCasbin.setPolicy(const aValue: IPolicyManager);
begin
  if not Assigned(aValue) then
    raise ECasbinException.Create('Policy Manager in nil');
  fPolicy:=aValue;
end;

initialization
  criticalSection:=TCriticalSection.Create;

finalization
  criticalSection.Free;

end.
