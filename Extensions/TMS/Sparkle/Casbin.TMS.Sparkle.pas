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
  System.Rtti,
  System.SysUtils, Casbin, Casbin.Model, Casbin.Policy;

function executeRequest(const aInstance: TObject;
                        const aCommand: string;
                        const aRequest: THttpServerRequest;
                        var aResponse:THttpServerResponse): boolean;
var
  ctx: TRTTIContext;
  cType: TRttiType;
  cMethod: TRttiMethod;
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

  cMethod:=cType.GetMethod(aCommand);
  if Assigned(cMethod) then
  begin
    aResponse.Close(TEncoding.UTF8.GetBytes('Method '+aCommand+' found'));
    Result:=True;
  end
  else
  begin
    aResponse.Close(TEncoding.UTF8.GetBytes('Method '+aCommand+' not found'));
    Result:=True;
  end;

end;

end.
