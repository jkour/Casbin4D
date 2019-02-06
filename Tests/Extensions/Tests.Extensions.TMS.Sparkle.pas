unit Tests.Extensions.TMS.Sparkle;

interface
uses
  DUnitX.TestFramework, Sparkle.InProc.Server, Casbin.TMS.Sparkle.Middleware,
  Sparkle.HttpServer.Request, Sparkle.HttpServer.Response, IdHTTP,
  Sparkle.HttpServer.Module, Sparkle.HttpServer.Context, Sparkle.Indy.Server;

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
    fServer: TIndySparkleHTTPServer;
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

    [Test]
    [TestCase ('Casbin.Enforce.1',
               '/enforce?params=alice,data1,read#true','#')]
    [TestCase ('Casbin.Enforce.2',
               '/enforce?params=alice,data1,write#false','#')]
    procedure testGetMethods(const url, aResult: string);
  end;

implementation

uses
  System.SysUtils;

const
  serverURL = 'http://localhost:8081/casbin4D';
  accessURL = 'http://localhost:8081/casbin4D';

procedure TTestCasbinTMSSparkle.Setup;
begin
end;

procedure TTestCasbinTMSSparkle.SetupFixture;
begin
  fModule:=TTestModule.Create(serverURL);

  fCasbinMiddleware:=TTestCasbinMiddleware.Create
      ('..\..\Examples\Default\basic_model.conf',
       '..\..\Examples\Default\basic_policy.csv');

  fModule.AddMiddleware(fCasbinMiddleware);

  fServer:=TIndySparkleHTTPServer.Create(nil);
  fServer.DefaultPort:=8081;
  fServer.Dispatcher.AddModule(fModule);
//  fServer.Dispatcher.AddModule(TAnonymousServerModule.Create(
//      serverURL,
//      procedure (const C: THttpServerContext)
//      begin
//        C.Response.StatusCode:=200;
//        C.Response.ContentType:='text/plain';
//  C.Response.Close(TEncoding.UTF8.GetBytes('All Good with server'));
//      end));

  fServer.Active:=True;

  fIdHTTP:=TIdHTTP.Create;
end;

procedure TTestCasbinTMSSparkle.TearDown;
begin

end;

procedure TTestCasbinTMSSparkle.TearDownFixture;
begin
  fServer.Free;
  fIdHTTP.Free;
end;

procedure TTestCasbinTMSSparkle.testGetMethods(const url, aResult: string);
var
  res: string;
begin
  res:=fIdHTTP.Get(accessURL+Trim(url));
  Assert.AreEqual(Trim(aResult), trim(res));
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
