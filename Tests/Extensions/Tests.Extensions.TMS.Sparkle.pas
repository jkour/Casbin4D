unit Tests.Extensions.TMS.Sparkle;

interface
uses
  DUnitX.TestFramework, Sparkle.InProc.Server, Casbin.TMS.Sparkle.Middleware,
  Sparkle.HttpServer.Request, Sparkle.HttpServer.Response, IdHTTP,
  Sparkle.HttpServer.Module, Sparkle.HttpServer.Context;

type

  TTestCasbinMiddleware = class (TCasbinMiddleware)
  public
    function getResponse: THttpServerResponse;
  end;

  TTestModule = class (THTTPServerModule)
  protected
    procedure ProcessRequest(const Context: THttpServerContext); override;
  end;

  [TestFixture]
  TTestCasbinTMSSparkle = class(TObject)
  private
    fServer: TInProcHttpServer;
    fIdHTTP: TIdHttp;
    fCasbinMiddleware: TTestCasbinMiddleware;
    fModule: THttpServerModule;
  public
    [SetupFixture]
    procedure SetupFixture;

    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [TearDownFixture]
    procedure TearDownFixture;

    // Sample Methods
    // Simple single Test
    [Test]
    procedure Test1;
    // Test with TestCase Attribute to supply parameters.
    [Test]
    [TestCase('TestA','1,2')]
    [TestCase('TestB','3,4')]
    procedure Test2(const AValue1 : Integer;const AValue2 : Integer);
  end;

implementation

uses
  System.SysUtils;

const
  accessURL = 'http://local://testserver/casbin4D';

procedure TTestCasbinTMSSparkle.Setup;
begin
end;

procedure TTestCasbinTMSSparkle.SetupFixture;
begin
//  fModule:=TTestModule.Create(accessURL);
//
//  fCasbinMiddleware:=TTestCasbinMiddleware.Create;
//  fModule.AddMiddleware(fCasbinMiddleware);

  fServer:=TInProcHttpServer.Get('testserver');
  fServer.Get('testserver').Dispatcher.AddModule(TAnonymousServerModule.Create(
    accessURL+'/authorise',
    procedure (const C: THttpServerContext)
    begin
      C.Response.StatusCode:=200;
    end));
//  fServer.Get('testserver').Dispatcher.AddModule(fModule);

  fIdHTTP:=TIdHTTP.Create;
end;

procedure TTestCasbinTMSSparkle.TearDown;
begin

end;

procedure TTestCasbinTMSSparkle.TearDownFixture;
begin
  fIdHTTP.Free;
end;

procedure TTestCasbinTMSSparkle.Test1;
begin
end;

procedure TTestCasbinTMSSparkle.Test2(const AValue1 : Integer;const AValue2 : Integer);
begin
end;

{ TTestCasbinMiddleware }

function TTestCasbinMiddleware.getResponse: THttpServerResponse;
var
  context: THttpServerContext;
  next: THttpServerProc;
begin
  ProcessRequest(context, next);
  Result:=context.Response;
end;

{ TTestModule }

procedure TTestModule.ProcessRequest(const Context: THttpServerContext);
begin
  Context.Response.StatusCode:=200;
  Context.Response.ContentType:='text/plain';
  Context.Response.Close(TEncoding.UTF8.GetBytes('All Good'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCasbinTMSSparkle);
end.
