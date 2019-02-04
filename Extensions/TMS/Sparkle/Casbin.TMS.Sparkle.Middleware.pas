unit Casbin.TMS.Sparkle.Middleware;

interface

uses
  Casbin.TMS.Sparkle.Middleware.Types, Sparkle.HttpServer.Module,
  Sparkle.HttpServer.Context, Casbin.Types, Casbin.Model.Types,
  Casbin.Policy.Types, System.Generics.Collections;

type
  TCasbinMiddleware = class(THttpServerMiddleware, ICasbinMiddleware)
  private
    fCasbin: ICasbin;
    fMethods: TList<string>;
    procedure loadURIs;
  protected
    procedure ProcessRequest(Context: THttpServerContext; Next: THttpServerProc); override;
  public
    constructor Create; overload;
    constructor Create(const aModelFile, aPolicyFile: string); overload;
    constructor Create(const aModel: IModel; const aPolicyAdapter: IPolicyManager);
        overload;
    constructor Create(const aModelFile: string; const aPolicyAdapter: IPolicyManager);
        overload;
    constructor Create(const aModel: IModel; const aPolicyFile: string);
        overload;
    destructor Destroy; override;
  end;

implementation

uses
  Casbin, System.SysUtils, System.Rtti, Casbin.Core.Logger.Types,
  Casbin.TMS.Sparkle, Casbin.Model, Casbin.Policy, Casbin.Core.Logger.Default;

{ TCasbinMiddleware }

constructor TCasbinMiddleware.Create;
begin
  fMethods:=TList<string>.Create;
  loadURIs;
  fCasbin:=TCasbin.Create;
end;

constructor TCasbinMiddleware.Create(const aModelFile, aPolicyFile: string);
begin
  inherited Create;
  fCasbin:=nil;
  fCasbin:=TCasbin.Create(aModelFile, aPolicyFile);
end;

constructor TCasbinMiddleware.Create(const aModel: IModel;
  const aPolicyAdapter: IPolicyManager);
begin
  inherited Create;
  fCasbin:=nil;
  fCasbin:=TCasbin.Create(aModel, aPolicyAdapter);
end;

constructor TCasbinMiddleware.Create(const aModelFile: string;
  const aPolicyAdapter: IPolicyManager);
begin
  inherited Create;
  fCasbin:=nil;
  fCasbin:=TCasbin.Create(aModelFile, aPolicyAdapter);
end;

constructor TCasbinMiddleware.Create(const aModel: IModel;
  const aPolicyFile: string);
begin
  inherited Create;
  fCasbin:=nil;
  fCasbin:=TCasbin.Create(aModel, aPolicyFile);
end;

destructor TCasbinMiddleware.Destroy;
begin
  fMethods.free;
  inherited;
end;

procedure TCasbinMiddleware.loadURIs;
var
  ctx: TRttiContext;
  method: TRttiMethod;
  methodName: string;

begin
  // Load ICasbin
  for method in (ctx.GetType(TypeInfo(ICasbin)) as TRttiInterfaceType).GetMethods do
  begin
    methodName:=method.Name;
    if (not methodName.StartsWith('get')) and
         (not methodName.StartsWith('set')) and
           (not fMethods.Contains(methodName)) then
      fMethods.Add('/'+method.Name);
  end;

  // Load IModel
  for method in (ctx.GetType(TypeInfo(IModel)) as TRttiInterfaceType).GetMethods do
  begin
    methodName:=method.Name;
    if (not methodName.StartsWith('get')) and
         (not methodName.StartsWith('set')) and
           (not fMethods.Contains('/'+methodName)) then
      fMethods.Add('/Model/'+method.Name);
  end;

  // Load IPolicyManager
  for method in (ctx.GetType(TypeInfo(IPolicyManager)) as TRttiInterfaceType).GetMethods do
  begin
    methodName:=method.Name;
    if (not methodName.StartsWith('get')) and
         (not methodName.StartsWith('set')) and
           (not fMethods.Contains('/'+methodName)) then
      fMethods.Add('/PolicyManager/'+method.Name);
  end;

  // Logger
  for method in (ctx.GetType(TypeInfo(ILogger)) as TRttiInterfaceType).GetMethods do
  begin
    methodName:=method.Name;
    if (not methodName.StartsWith('get')) and
         (not methodName.StartsWith('set')) and
           (not fMethods.Contains('/'+methodName)) then
      fMethods.Add('/Logger/'+method.Name);
  end;
end;

procedure TCasbinMiddleware.ProcessRequest(Context: THttpServerContext;
  Next: THttpServerProc);
var
  request: THttpServerRequest;
  response: THttpServerResponse;
  segments: TArray<string>;
  reqContext: string;
  command: string;
  executed: Boolean;
  activeObject: TObject;
begin
  executed:=False;
  request:=Context.Request;
  segments:=request.Uri.Segments;
  if Length(segments)>2 then
  begin
    reqContext:=segments[Length(segments)-2];
    command:=segments[Length(segments)-1];
  end;
  if UpperCase(command)='LIST' then
  begin
    if request.MethodType=THTTPMethod.Get then
    begin
      Context.Response.StatusCode:=200;
      Context.Response.ContentType:='text/plain';
      Context.Response.Close(TEncoding.UTF8.GetBytes('Available URIs:'+sLineBreak+
                                      string.Join(sLineBreak,fMethods.ToArray)));
    end
    else
    begin
      Context.Response.StatusCode:=405; // Not Allowed
      Context.Response.ContentType:='text/plain';
      Context.Response.Close(TEncoding.UTF8.GetBytes('Method not allowed. Use GET instead'));
    end;
    executed:=True;
  end
  else
  begin
    activeObject:=nil;
    response:=Context.Response;

    if fMethods.Contains('/'+command) then
      activeObject:=fCasbin as TCasbin;
    if fMethods.Contains('/'+reqContext+'/'+command) then
    begin
      if UpperCase(reqContext)='MODEL' then
        activeObject:= fCasbin.Model as TModel;
      if UpperCase(reqContext)='POLICYMANAGER' then
        activeObject:= fCasbin.Policy as TPolicyManager;
      if UpperCase(reqContext)='LOGGER' then
        activeObject:= fCasbin.Logger as TDefaultLogger;
    end;

    if Assigned(activeObject) then
      executed:=executeRequest(activeObject, command, request, response);
  end;

  if not executed then
    Next(Context);
end;

end.
