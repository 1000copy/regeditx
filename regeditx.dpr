program regeditx;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  AliasOfSys in 'AliasOfSys.pas',
  ukeyForm in 'ukeyForm.pas';

{$R *.res}
var KeyNameForm1:KeyNameForm;
begin
  Application.Initialize;
//  Application.CreateForm(TKeyNameForm1, KeyNameForm1);
//  Application.CreateForm(TForm1, Form1);
  KeyNameForm1 := KeyNameForm.CreateNew(nil);
  Application.MainForm := KeyNameForm1;
  Application.Run;
end.
