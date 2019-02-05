unit Casbin.TMS.Sparkle.URI;

interface

uses
  Sparkle.HttpServer.Request;

type
  TCasbinMethodContext = (cmcCasbin, cmcLogger, cmcModel, cmcPolicyManager);
  TCasbinURLOperation = Sparkle.HttpServer.Request.THttpMethod;

  TCasbinSparkleMethod = record
    ID: Integer;
    Name: string;
    Tags: TArray<string>;
    Context: TCasbinMethodContext;
    URLOperation: TCasbinURLOperation;
  end;

const
  casbinMethods = 1;
  loggerMethods = 2;
  {TODO -oOwner -cGeneral : Add Methods for Model}
  modelMethods = 0;
  {TODO -oOwner -cGeneral : Add Methods for PolicyManager}
  policyMethods = 0;

  availableURIs : array
        [0..casbinMethods+loggerMethods+modelMethods+policyMethods-1] of
          TCasbinSparkleMethod =
  (
  // Casbin
  (ID:0; Name:'/enforce'; Tags: ['params']; Context: cmcCasbin; URLOperation: THttpMethod.GET),

  // Logger
  (ID:1; Name:'/Logger/'; Tags: ['enabled']; Context: cmcLogger; URLOperation: THttpMethod.PUT),
  (ID:2; Name:'/Logger/LastLoggedMessage';
        Tags: []; Context: cmcLogger; URLOperation: THttpMethod.GET)
  // Model

  // PolicyManager
  );

function availableURIPaths: TArray<string>;
function URIDetails (const aContext: TCasbinMethodContext;
                     const aMethod: string): TCasbinSparkleMethod;


implementation

uses
  System.SysUtils;

function availableURIPaths: TArray<string>;
var
  i: integer;
begin
  SetLength(Result, Length(availableURIs));
  for i:=0 to Length(availableURIs)-1 do
  begin
    Result[i]:=availableURIs[i].Name;
  end;
end;

function URIDetails (const aContext: TCasbinMethodContext;
                     const aMethod: string): TCasbinSparkleMethod;
var
  rec: TCasbinSparkleMethod;
begin
  result.Context:=aContext;
  Result.Name:='NULL';
  Result.Tags:=[];
  Result.URLOperation:=THttpMethod.GET;

  for rec in availableURIs do
  begin
    if (rec.Context=aContext) and (upperCase(rec.Name)= UpperCase(aMethod)) then
    begin
      Result:=rec;
      Break;
    end;
  end;
end;

end.
