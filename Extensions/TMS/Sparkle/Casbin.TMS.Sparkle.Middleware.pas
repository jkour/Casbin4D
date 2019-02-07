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
  end;

implementation

uses
  Casbin, System.SysUtils, System.Rtti, Casbin.Core.Logger.Types,
  Casbin.Model, Casbin.Policy, Casbin.Core.Logger.Default,
  Casbin.TMS.Sparkle.URI, System.Generics.Collections, System.StrUtils,
  Sparkle.Utils, Casbin.Core.Base.Types, Bcl.Json;

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
  inherited;
  fCasbin:=TCasbin.Create;
end;

constructor TCasbinMiddleware.Create(const aModelFile, aPolicyFile: string);
begin
  inherited Create;
  fCasbin:=TCasbin.Create(aModelFile, aPolicyFile);
end;

constructor TCasbinMiddleware.Create(const aModel: IModel;
  const aPolicyAdapter: IPolicyManager);
begin
  inherited Create;
  fCasbin:=TCasbin.Create(aModel, aPolicyAdapter);
end;

constructor TCasbinMiddleware.Create(const aModelFile: string;
  const aPolicyAdapter: IPolicyManager);
begin
  inherited Create;
  fCasbin:=TCasbin.Create(aModelFile, aPolicyAdapter);
end;

constructor TCasbinMiddleware.Create(const aModel: IModel;
  const aPolicyFile: string);
begin
  inherited Create;
  fCasbin:=TCasbin.Create(aModel, aPolicyFile);
end;

procedure TCasbinMiddleware.ProcessRequest(Context: THttpServerContext;
  Next: THttpServerProc);
var
  request: THttpServerRequest;
  segments: TArray<string>;
  reqContext: string;
  command: string;
  executed: Boolean;
  methodContext: TCasbinMethodContext;
  methodRec: TCasbinSparkleMethod;
  args: TArray<TPair<string, string>>;
  methodResult: TValue;
  arrParams: TFilterArray;
  uriPath: string;
begin
  request:=Context.Request;
  segments:=request.Uri.Segments;
  command:=segments[Length(segments)-1];
  if UpperCase(command)='LIST' then
  begin
    if request.MethodType=THTTPMethod.Get then
    begin
      Context.Response.StatusCode:=200;
      Context.Response.ContentType:='text/plain';
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
    begin
      if Length(segments)>2 then
      begin
        case IndexStr(UpperCase(segments[Length(segments)-1]),
                      ['','LOGGER']) of
          0: methodContext:=cmcCasbin;
          1: methodContext:=cmcLogger;
        end;
      end;
    end;

    uriPath:='/'+command;
    if trim(reqContext)<>'' then
      uriPath:='/'+Trim(reqContext)+uriPath;
    methodRec:=URIDetails(methodContext, uriPath);
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
          case methodRec.Context of
            cmcCasbin: begin
                         case methodRec.ID of
                           0: begin  // enforce
                                arrParams:=argValue(args, methodRec.Tags[0]).Split([',']);
                                methodResult:=fCasbin.enforce(TFilterArray(arrParams));
                                TJSON.Serialize(methodResult, Context.Response.Content);
                                Context.Response.Close;
                              end;
                           1: fCasbin.Enabled:=true;
                           2: fCasbin.Enabled:=False;
                         end;
                       end;
            cmcLogger: begin
                          case methodRec.ID of
                           3: begin  // Logger?enable=true/false
                                arrParams:=argValue(args, methodRec.Tags[0]).Split([',']);
                                if Length(arrParams)=1 then
                                  fCasbin.Logger.Enabled:=
                                      UpperCase(arrParams[0]) = 'TRUE';
                              end;
                           4: begin  // Logger/LastLoggedMessage
                                methodResult:=fCasbin.Logger.LastLoggedMessage;
                                TJSON.Serialize(methodResult, Context.Response.Content);
                                Context.Response.Close;
                              end;
                         end;
                       end;
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
