unit ukeyForm;

interface
uses forms,StdCtrls,Classes,Controls;
 type
  KeyNameForm = class(TForm)
    FLabel :TLabel;
    FEdit :TEdit;
    FButton : TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  public
   constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
   class  function GetKeyName(OldKeyName:String=''):string;
  end;

implementation


class function KeyNameForm.GetKeyName(OldKeyName:String=''):string;
var kn : KeyNameForm;
begin
  result := '';
  kn := KeyNameForm.CreateNew(nil);
  kn.FEdit.Text := oldKeyName;
  if mrOK = kn.ShowModal then
    result := kn.FEdit.text;
  kn.Free;
end;
constructor KeyNameForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
const buttonY : integer = 34;
const TextY : integer = 10;
begin
  inherited CreateNew(AOwner);
  self.Position := poOwnerFormCenter ;
  OnClose := FormClose;

  FLabel := TLabel.Create(Self);
  FLabel.SetBounds(10, TextY, 60, 24);
  FLabel.Parent := Self;
  FLabel.Caption := 'New Key Name';

  FEdit := TEdit.Create(Self);
  FEdit.SetBounds(100, TextY, 100, 24);
  FEdit.Parent := Self;

  FButton := TButton.Create(Self);
  FButton.SetBounds(10, ButtonY, 60, 24);
  FButton.Caption := 'OK';
  FButton.Parent := Self;
  FButton.ModalResult := mrOK;
  FButton := TButton.Create(Self);
  FButton.SetBounds(80, ButtonY, 60, 24);
  FButton.Caption := 'Cancel';
  FButton.Parent := Self;
  FButton.ModalResult := mrCancel;
end;

procedure KeyNameForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;
end.
 