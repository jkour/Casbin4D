unit Casbin.TMS.Sparkle;

interface

uses
  Sparkle.HttpServer.Request, Sparkle.HttpServer.Response;

function executeRequest(const aInstance: TObject;
                        const aCommand: string;
                        const aRequest: THttpServerRequest;
                        var aResponse:THttpServerResponse): boolean;

implementation

uses
  System.Rtti, System.SysUtils, Casbin, Casbin.Model, Casbin.Policy,
  Casbin.Core.Logger.Base, System.Generics.Collections,
  Sparkle.Utils, System.TypInfo;

function executeRequest(const aInstance: TObject;
                        const aCommand: string;
                        const aRequest: THttpServerRequest;
                        var aResponse:THttpServerResponse): boolean;
begin
  if not Assigned(aInstance) then
    raise Exception.Create('The Instance in executeRequest is nil');
  if (not (aInstance is TCasbin)) and (not (aInstance is TModel)) and
        (not (aInstance is TPolicyManager)) then
    raise Exception.Create('The Instance in executeRequest is not the correct class type');

  Result:=False;
end;


  // Initially methods were loaded via RTTI but in executeRequest it is
  // difficult to RELIABLY check the correct parameters for the
  // requested methods
  // For now, the Casbin methods exposed in Sparkle are hard-coded

{$REGION 'RTTI Attempt'}
{
function executeRequest(const aInstance: TObject;
                        const aCommand: string;
                        const aRequest: THttpServerRequest;
                        var aResponse:THttpServerResponse): boolean;
var
  ctx: TRTTIContext;
  cType: TRttiType;
  cMethod: TRttiMethod;
  args: TArray<TPair<string, string>>;
  argsPair: TPair<string, string>;
  paramsStr: string;
  tmpStr: string;
  cParamsValue: array of TValue;
  cParams: TArray<TRttiParameter>;
  cResult: TValue;
begin
  if not Assigned(aInstance) then
    raise Exception.Create('The Instance in executeRequest is nil');
  if (not (aInstance is TCasbin)) and (not (aInstance is TModel)) and
        (not (aInstance is TPolicyManager)) then
    raise Exception.Create('The Instance in executeRequest is not the correct class type');

  Result:=False;

  if aInstance is TCasbin then
    cType:=ctx.GetType(TCasbin);
  if aInstance is TModel then
    cType:=ctx.GetType(TModel);
  if aInstance is TPolicyManager then
    cType:=ctx.GetType(TPolicyManager);
  if aInstance is TBaseLogger then
    cType:=ctx.GetType(TBaseLogger);

  cMethod:=cType.GetMethod(aCommand);
  if Assigned(cMethod) then
  begin
    SetLength(cParamsValue, 0);
    args:=TSparkleUtils.GetQueryParams(aRequest.Uri.OriginalQuery);
    cParams:=cMethod.GetParameters;
    case cMethod.MethodKind of
      mkProcedure: begin
                     if aRequest.MethodType=THTTPMethod.Put then
                     begin

                     end
                     else
                       aResponse.Close(
                          TEncoding.UTF8.GetBytes('Wrong Method Type. Use PUT instead'));
                   end;
      mkFunction: begin
                     if aRequest.MethodType=THTTPMethod.Get then
                     begin
                       for argsPair in args do
                       begin
                         if argsPair.Key = 'params' then
                         begin
                           for tmpStr in argsPair.Value.Split([',']) do
                           begin
                             SetLength(cParamsValue, Length(cParamsValue)+1);
                             cParamsValue[Length(cParamsValue)-1]:=tmpStr;
                           end;
                           Break;
                         end;
                       end;
                       cResult:=cMethod.Invoke(aInstance, cParamsValue);
                     end
                     else
                       aResponse.Close(
                          TEncoding.UTF8.GetBytes('Wrong Method Type. Use GET instead'));
                   end;
    end;
    Result:=True;
  end
  else
  begin
    aResponse.Close(TEncoding.UTF8.GetBytes('Method '+aCommand+' not found'));
    Result:=True;
  end;

end;
  }
{$ENDREGION}

end.
