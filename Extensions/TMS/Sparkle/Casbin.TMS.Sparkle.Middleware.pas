unit Casbin.TMS.Sparkle.Middleware;

interface

uses
  Casbin.TMS.Sparkle.Middleware.Types, Sparkle.HttpServer.Module,
  Sparkle.HttpServer.Context, Casbin.Types, Casbin.Model.Types,
  Casbin.Policy.Types;

type
  TCasbinMiddleware = class(THttpServerMiddleware, ICasbinMiddleware)
  private
    fCasbin: ICasbin;
//    fMethods: TList<string>;
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
  Casbin.TMS.Sparkle, Casbin.Model, Casbin.Policy, Casbin.Core.Logger.Default,
  Casbin.TMS.Sparkle.URI, System.Generics.Collections, System.StrUtils,
  Sparkle.Utils, Casbin.Core.Base.Types, Sparkle.Json.Writer;

function argValue (const aArgs: TArray<TPair<string, string>>;
                   const aKey: string): string;
var
  pair: TPair<string, string>;
begin
  Result:='';
  for pair in aArgs do
    if UpperCase(pair.Key)=UpperCase(aKey) then
    begin
      Result:=pair.Value;
      Break;
    end;
end;

{ TCasbinMiddleware }

constructor TCasbinMiddleware.Create;
begin
//  fMethods:=TList<string>.Create;
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
//  fMethods.free;
  inherited;
end;

procedure TCasbinMiddleware.loadURIs;
var
  ctx: TRttiContext;
  method: TRttiMethod;
  methodName: string;

begin
{$REGION 'RTTI Attempt'}
{
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
  }
{$ENDREGION}

  // Initially methods were loaded via RTTI but in executeRequest it is
  // difficult to RELIABLY check the correct parameters for the
  // requested methods
  // For now, the Casbin methods exposed in Sparkle are hard-coded

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
  methodContext: TCasbinMethodContext;
  methodRec: TCasbinSparkleMethod;
  args: TArray<TPair<string, string>>;
  methodResult: TValue;
  arrParams: TFilterArray;
  jsonWriter: TJSONWriter;
begin
  executed:=False;
  request:=Context.Request;
  segments:=request.Uri.Segments;
  command:=segments[Length(segments)-1];
  if UpperCase(command)='LIST' then
  begin
    if request.MethodType=THTTPMethod.Get then
    begin
      Context.Response.StatusCode:=200;
      Context.Response.ContentType:='text/plain';
//      Context.Response.Close(TEncoding.UTF8.GetBytes('Available URIs:'+sLineBreak+
//                                      string.Join(sLineBreak,fMethods.ToArray)));
      Context.Response.Close(TEncoding.UTF8.GetBytes('Available URIs:'+sLineBreak+
                                      string.Join(sLineBreak, availableURIPaths)));
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
    if Length(segments)>3 then
    begin
      reqContext:=segments[Length(segments)-2];
      case IndexStr(UpperCase(reqContext),
                    ['MODEL','POLICYMANAGER','LOGGER']) of
        0: methodContext:=cmcModel;
        1: methodContext:=cmcPolicyManager;
        2: methodContext:=cmcLogger;
      end;
    end
    else
      methodContext:=cmcCasbin;

    methodRec:=URIDetails(methodContext, Trim(reqContext)+'/'+command);
    if methodRec.Name='NULL' then
      executed:=false
    else
    begin
      if TCasbinURLOperation(request.MethodType) <> methodRec.URLOperation then
      begin
        executed:=True;
        Context.Response.StatusCode:=400; // Bad Request
        Context.Response.ContentType:='text/plain';
        Context.Response.Close(TEncoding.UTF8.GetBytes
            ('Wrong Request Type for Method '+Trim(reqContext)+'/'+command));
      end
      else
      begin
        args:=TSparkleUtils.GetQueryParams(request.Uri.OriginalQuery);
        if (Length(args)<>Length(methodRec.Tags)) then
        begin
          executed:=True;
          Context.Response.StatusCode:=400; // Bad Request
          Context.Response.ContentType:='text/plain';
          Context.Response.Close(TEncoding.UTF8.GetBytes
                    ('Parameters are wrong'));
        end
        else
        begin
          executed:=True;
          Context.Response.StatusCode:=200;
          Context.Response.ContentType:='text/plain';
//          Context.Response.Close(TEncoding.UTF8.GetBytes('Available URIs:'+sLineBreak+
//                                      string.Join(sLineBreak, availableURIPaths)));
          case methodRec.Context of
            cmcCasbin: begin
                         case methodRec.ID of
                           0: begin  //enforce
                                arrParams:=argValue(args, methodRec.Tags[0]).Split([',']);
                                methodResult:=fCasbin.enforce(TFilterArray(arrParams));
                                jsonWriter:=TJsonWriter.Create(Context.Response.Content);
                                jsonWriter
//                                        .WriteBeginObject
                                            .WriteBoolean(methodResult.AsBoolean)
//                                          .WriteEndObject
                                           ;
                                jsonWriter.Free;
//                                Context.Response.Close;
                              end;
                         end;
                       end;
            cmcLogger: ;
            cmcModel: ;
            cmcPolicyManager: ;
          end;
        end;
      end;
    end;
  end;

  if not executed then
    Next(Context);
end;

end.
