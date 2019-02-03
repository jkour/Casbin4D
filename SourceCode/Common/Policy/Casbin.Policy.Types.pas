// Copyright 2018 by John Kouraklis and Contributors. All Rights Reserved.
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
unit Casbin.Policy.Types;

interface

uses
  Casbin.Core.Base.Types, Casbin.Model.Sections.Types,
  System.Generics.Collections, System.Rtti, System.Types;

const
  DefaultDomain = 'default';

type
  TRoleNode = class
  private
    fDomain: string;
    fID: string;
    fValue: string;
  public
    constructor Create(const aValue: String; const aDomain: string = DefaultDomain);
    property Domain: string read fDomain;
    property Value: string read fValue;
    property ID: string read fID write fID;
  end;

  IPolicyManager = interface (IBaseInvokableInterface)
    ['{B983A830-6107-4283-A45D-D74CDBB5E2EA}']
    function section (const aSlim: Boolean = true): string;
    function toOutputString: string;

    // Policies
    function policies: TList<string>;
    procedure addPolicy (const aSection: TSectionType; const aTag: string;
                              const aAssertion: string); overload;
    procedure addPolicy (const aSection: TSectionType;
                              const aAssertion: string); overload;
    procedure load (const aFilter: TFilterArray = []);
    function policy (const aFilter: TFilterArray = []): string;
    procedure clear;
    function policyExists (const aFilter: TFilterArray = []): Boolean;

    procedure removePolicy (const aFilter: TFilterArray = []);

    // Roles
    procedure clearRoles;
    function roles: TList<string>;
    function domains: TList<string>;
    function roleExists (const aFilter: TFilterArray = []): Boolean;

    procedure addLink(const aBottom: string; const aTop: string); overload;
    procedure addLink(const aBottom: string;
                      const aTopDomain: string; const aTop: string); overload;
    procedure addLink(const aBottomDomain: string; const aBottom: string;
                      const aTopDomain: string; const aTop: string); overload;
    procedure removeLink(const aLeft: string; const aRight: string); overload;
    procedure removeLink(const aLeft: string;
                      const aRightDomain: string; const aRight: string); overload;
    procedure removeLink(const aLeftDomain: string; const aLeft: string;
                      const aRightDomain: string; const aRight: string); overload;
    function linkExists(const aLeft: string; const aRight: string):boolean; overload;
    function linkExists(const aLeft: string;
                      const aRightDomain: string; const aRight: string):boolean; overload;
    function linkExists(const aLeftDomain: string; const aLeft: string;
                      const aRightDomain: string; const aRight: string):boolean; overload;

    function rolesForEntity (const aEntity: string; const aDomain: string =''):TStringDynArray;

    function EntitiesForRole (const aEntity: string; const aDomain: string =''):TStringDynArray;
  end;

implementation

uses
  System.SysUtils;

constructor TRoleNode.Create(const aValue: String; const aDomain: string =
    DefaultDomain);
var
  guid: TGUID;
begin
  inherited Create;
  fValue:=Trim(aValue);
  fDomain:=Trim(aDomain);
  if CreateGUID(guid) <> 0 then
    fID:=GUIDToString(TGUID.Empty)
  else
    fID:=GUIDToString(guid);
end;

end.
