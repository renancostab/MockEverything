program MockDemo;

uses
  Forms,
  Demo in 'Demo.pas' {Form1},
  MockCommon in '..\source\MockCommon.pas',
  MockEverything in '..\source\MockEverything.pas',
  MockMap in '..\source\MockMap.pas',
  MockProcedures in '..\source\MockProcedures.pas',
  CPUID in '..\ddetours\CPUID.pas',
  DDetours in '..\ddetours\DDetours.pas',
  InstDecode in '..\ddetours\InstDecode.pas',
  ClassTest in 'ClassTest.pas',
  MockRttiUtils in '..\source\MockRttiUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
