unit Casbin.TMS.Sparkle.Middleware.Types;

interface

uses
  Sparkle.HttpServer.Module;

type
  ICasbinMiddleware = interface (IHttpServerMiddleware)
    ['{F40D8CB1-5469-441C-A1BE-A65A911EF8A8}']
  end;
implementation

end.
