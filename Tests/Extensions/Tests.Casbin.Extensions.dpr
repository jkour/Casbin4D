program Tests.Casbin.Extensions;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Tests.Extensions.TMS.Sparkle in 'Tests.Extensions.TMS.Sparkle.pas',
  Casbin.TMS.Sparkle.Middleware.Types in '..\..\Extensions\TMS\Sparkle\Casbin.TMS.Sparkle.Middleware.Types.pas',
  Casbin.TMS.Sparkle.Middleware in '..\..\Extensions\TMS\Sparkle\Casbin.TMS.Sparkle.Middleware.pas',
  Casbin.Adapter.Types in '..\..\SourceCode\Common\Adapters\Casbin.Adapter.Types.pas',
  Casbin.Adapter.Policy.Types in '..\..\SourceCode\Common\Adapters\Casbin.Adapter.Policy.Types.pas',
  Casbin.Adapter.Memory.Policy in '..\..\SourceCode\Common\Adapters\Casbin.Adapter.Memory.Policy.pas',
  Casbin.Adapter.Memory in '..\..\SourceCode\Common\Adapters\Casbin.Adapter.Memory.pas',
  Casbin.Adapter.Filesystem.Policy in '..\..\SourceCode\Common\Adapters\Casbin.Adapter.Filesystem.Policy.pas',
  Casbin.Adapter.Filesystem in '..\..\SourceCode\Common\Adapters\Casbin.Adapter.Filesystem.pas',
  Casbin.Adapter.Base in '..\..\SourceCode\Common\Adapters\Casbin.Adapter.Base.pas',
  Casbin.Types in '..\..\SourceCode\Common\Casbin\Casbin.Types.pas',
  Casbin.Resolve.Types in '..\..\SourceCode\Common\Casbin\Casbin.Resolve.Types.pas',
  Casbin.Resolve in '..\..\SourceCode\Common\Casbin\Casbin.Resolve.pas',
  Casbin in '..\..\SourceCode\Common\Casbin\Casbin.pas',
  Casbin.Exception.Types in '..\..\SourceCode\Common\Core\Casbin.Exception.Types.pas',
  Casbin.Core.Utilities in '..\..\SourceCode\Common\Core\Casbin.Core.Utilities.pas',
  Casbin.Core.Strings in '..\..\SourceCode\Common\Core\Casbin.Core.Strings.pas',
  Casbin.Core.Defaults in '..\..\SourceCode\Common\Core\Casbin.Core.Defaults.pas',
  Casbin.Core.Base.Types in '..\..\SourceCode\Common\Core\Casbin.Core.Base.Types.pas',
  Casbin.Effect.Types in '..\..\SourceCode\Common\Effect\Casbin.Effect.Types.pas',
  Casbin.Effect in '..\..\SourceCode\Common\Effect\Casbin.Effect.pas',
  Casbin.Functions.Types in '..\..\SourceCode\Common\Functions\Casbin.Functions.Types.pas',
  Casbin.Core.Logger.Types in '..\..\SourceCode\Common\Loggers\Casbin.Core.Logger.Types.pas',
  Casbin.Core.Logger.Default in '..\..\SourceCode\Common\Loggers\Casbin.Core.Logger.Default.pas',
  Casbin.Core.Logger.Base in '..\..\SourceCode\Common\Loggers\Casbin.Core.Logger.Base.pas',
  Casbin.Matcher.Types in '..\..\SourceCode\Common\Matcher\Casbin.Matcher.Types.pas',
  Casbin.Matcher in '..\..\SourceCode\Common\Matcher\Casbin.Matcher.pas',
  Casbin.Model.Types in '..\..\SourceCode\Common\Model\Casbin.Model.Types.pas',
  Casbin.Model.Sections.Types in '..\..\SourceCode\Common\Model\Casbin.Model.Sections.Types.pas',
  Casbin.Model.Sections.Default in '..\..\SourceCode\Common\Model\Casbin.Model.Sections.Default.pas',
  Casbin.Model in '..\..\SourceCode\Common\Model\Casbin.Model.pas',
  Casbin.Parser.Types in '..\..\SourceCode\Common\Parser\Casbin.Parser.Types.pas',
  Casbin.Parser in '..\..\SourceCode\Common\Parser\Casbin.Parser.pas',
  Casbin.Parser.AST.Types in '..\..\SourceCode\Common\Parser\Casbin.Parser.AST.Types.pas',
  Casbin.Parser.AST in '..\..\SourceCode\Common\Parser\Casbin.Parser.AST.pas',
  Casbin.Policy.Types in '..\..\SourceCode\Common\Policy\Casbin.Policy.Types.pas',
  Casbin.Policy in '..\..\SourceCode\Common\Policy\Casbin.Policy.pas',
  ArrayHelper in '..\..\SourceCode\Common\Third Party\ArrayHelper\ArrayHelper.pas',
  ParseExpr in '..\..\SourceCode\Common\Third Party\TExpressionParser\ParseExpr.pas',
  ParseClass in '..\..\SourceCode\Common\Third Party\TExpressionParser\ParseClass.pas',
  oObjects in '..\..\SourceCode\Common\Third Party\TExpressionParser\oObjects.pas',
  Casbin.Functions in '..\..\SourceCode\Common\Functions\Casbin.Functions.pas',
  Casbin.TMS.Sparkle.URI in '..\..\Extensions\TMS\Sparkle\Casbin.TMS.Sparkle.URI.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.




