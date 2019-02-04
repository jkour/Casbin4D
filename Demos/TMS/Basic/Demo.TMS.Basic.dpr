program Demo.TMS.Basic;

{$APPTYPE CONSOLE}

uses
  {$IFDEF EurekaLog}
  EMemLeaks,
  EResLeaks,
  EDialogConsole,
  EDebugExports,
  EDebugJCL,
  EFixSafeCallException,
  EMapWin32,
  EAppConsole,
  ExceptionLog7,
  {$ENDIF EurekaLog}
  System.SysUtils,
  Sparkle.HttpServer.Context,
  Sparkle.HttpServer.Module,
  Sparkle.HttpSys.Server,
  Casbin.TMS.Sparkle.Middleware in '..\..\..\Extensions\TMS\Sparkle\Casbin.TMS.Sparkle.Middleware.pas',
  Casbin.TMS.Sparkle.Middleware.Types in '..\..\..\Extensions\TMS\Sparkle\Casbin.TMS.Sparkle.Middleware.Types.pas',
  Casbin.TMS.Sparkle in '..\..\..\Extensions\TMS\Sparkle\Casbin.TMS.Sparkle.pas';

type
  TAuthoriseModule = class(THttpServerModule)
    public procedure ProcessRequest(const C: THttpServerContext); override;
  end;

procedure TAuthoriseModule.ProcessRequest(const C: THttpServerContext);
begin
  C.Response.StatusCode := 200;
  C.Response.ContentType := 'text/plain';
  C.Response.Close(TEncoding.UTF8.GetBytes('Hello from Authorisation Module'));
end;

// *************************************
// NEED TO RESERVE http://+:2001/casbin4D in Windows
// *************************************

const
  ServerUrl = 'http://localhost:2001/casbin4D/authorise';

var
  Server: THttpSysServer;
  authModule: TAuthoriseModule;
  casbinMiddleware: TCasbinMiddleware;

begin
  Server := THttpSysServer.Create;
  try
    authModule:=TAuthoriseModule.Create(ServerUrl);

    casbinMiddleware:=TCasbinMiddleware.Create;

    authModule.AddMiddleware(casbinMiddleware);

    Server.AddModule(authModule);
    Server.Start;
    WriteLn('TMS Sparkle Server with Casbin4D support started at ' + ServerUrl);
    WriteLn('Press Enter to stop');
    ReadLn;
    Server.Stop;
  finally
    Server.Free;
  end;
end.

