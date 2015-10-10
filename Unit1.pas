unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, DBClient, Grids, DBGrids, ExtCtrls,AliasOfSys,ukeyForm;

type
  TForm1 = class(TForm)
    dbgrd1: TDBGrid;
    ds1: TDataSource;
    pnl1: TPanel;
    edt1: TEdit;
    btn2: TButton;
    cbb1: TComboBox;
    btnUp: TButton;
    btnDel: TButton;
    btnEdit: TButton;
    btnRoot: TButton;
    btnAdd: TButton;
    btnTest: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure dbgrd1DblClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure btnRootClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure cbb1Change(Sender: TObject);
    procedure edt1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edt1KeyPress(Sender: TObject; var Key: Char);
    procedure dbgrd1KeyPress(Sender: TObject; var Key: Char);
    procedure dbgrd1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnTestClick(Sender: TObject);
  private
    procedure Load(w: DWORD; Key: String);
    procedure ReloadReg;
    procedure NavigateDown(path: string);
    { Private declarations }
  public
    { Public declarations }
    ds2 : MemTable;
  end;

var
  Form1: TForm1;

implementation
uses registry;
{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  ds2 := MemTable.Create(nil);
  ds2.FieldDefs.Add('Name',  ftString, 250, False);
  ds2.FieldDefs.Add('Value', ftString,  250, False);
  ds2.FieldDefs.Add('Type',  ftString,   250, False);
  (ds2).createTable;
  ds2.Open;
  ds2.Fields[0].DisplayWidth := 25 ;
  ds2.Fields[1].DisplayWidth := 25 ;
  ds2.Fields[2].DisplayWidth := 25 ;

  Self.edt1.Text := '';
  Self.ReloadReg;
  Self.ds1.DataSet := ds2;
  //  Self.btn2.Default := true;
  self.btnTest.Visible := False;
end;

procedure TForm1.btn1Click(Sender: TObject);
var
  reg        : TRegistry;
  openResult : Boolean;
  today      : TDateTime;
begin
  reg := TRegistry.Create(KEY_READ);
   reg.RootKey := HKEY_CURRENT_USER;// HKEY_LOCAL_MACHINE;
 
  if (not reg.KeyExists('Software\MyCompanyName\MyApplication\')) then
    begin
      MessageDlg('Key not found! Created now.',
					        mtInformation, mbOKCancel, 0);
    end;
  reg.Access := KEY_WRITE;
  openResult := reg.OpenKey('Software\MyCompanyName\MyApplication\',True);

  if not openResult = True then
    begin
      MessageDlg('Unable to create key! Exiting.',
                  mtError, mbOKCancel, 0);
      exit;
    end;

  { Checking if the values exist and inserting when neccesary }

  if not reg.KeyExists('CreationDate') then
    begin
      today := Now;
  		reg.WriteDateTime('CreationDate', today);
    end;
 
  if not reg.KeyExists('LicencedTo') then
    begin
  		reg.WriteString('LicencedTo', 'MySurname\ MyFirstName');
    end;

  if not reg.KeyExists('AppLocation') then
    begin
  		reg.WriteExpandString('AppLocation',
                            '%PROGRAMFILES%\MyCompanyName\MyApplication\');
    end;
 
  if not reg.KeyExists('ProjectsLocation') then
    begin
  		reg.WriteExpandString('ProjectsLocation',
                            '%USERPROFILE%\MyApplication\Projects\');
    end;
  if not reg.KeyExists('ShowCount') then
    begin
  		reg.WriteInteger('ShowCount',
                            1);
    end;
  reg.CloseKey();
  reg.Free;

end;
function Tostr(r:TRegDataType):string;
var s:string;
begin

      case r of
        rdUnknown: s := 'Unknown';
        rdString: s := 'String';
        rdExpandString: s := 'ExpandString';
        rdInteger: s := 'Integer';
        rdBinary: s := 'Binary';
      end;
      result := s;
end;
function LowCase(Ch: WideChar): WideChar;
begin
  Result := Ch;
  case Ch of
    'A'..'Z':
      Result := WideChar(Word(Ch) + 32 );
  end;
end;
function ByteToHex(InByte:byte):shortstring;
const Digits:array[0..15] of char='0123456789ABCDEF';
begin
 result:=digits[InByte shr 4]+digits[InByte and $0F];
end;

function ConvertBinerToHex ( const nBinaryValue   : array of byte;
                             const nLengthInBytes : integer        ) : string;
var
  I : integer;
begin
  result := '' ;
   for i:= 0 to nLengthInBytes - 1 do
     result := result + bytetohex( nBinaryValue[i])+' ';
   result := trim(result)
end;
//function ConvertBinerToHex ( const nBinaryValue   : array of byte;
//                             const nLengthInBytes : integer        ) : string;
//var
//  I : integer;
//begin
//  setlength ( Result, 2 * nLengthInBytes );
//  if nLengthInBytes > 0 then
//    begin
//      BinToHex( @(nBinaryValue[0]), pchar(Result), length(Result) );
//      Result := lowercase ( Result );
////      for I := length(Result) downto 3 do
////        if odd(I) then
////          Insert ( ',', Result, I );
//    end;
//end;
function toHk(s:string): DWORD;
begin
  s := Trim(s);
  if s = 'HKEY_CLASSES_ROOT' then
   result := HKEY_CLASSES_ROOT
  else if s = 'HKEY_CURRENT_USER' then result := HKEY_CURRENT_USER
  else if s=  'HKEY_LOCAL_MACHINE' then result := HKEY_LOCAL_MACHINE
    else if s=  'HKEY_USERS' then result := HKEY_USERS
      else if s=  'HKEY_PERFORMANCE_DATA' then result := HKEY_PERFORMANCE_DATA
        else if s=  'HKEY_CURRENT_CONFIG' then result := HKEY_CURRENT_CONFIG
          else if s=  'HKEY_DYN_DATA' then result := HKEY_DYN_DATA
  else
    result :=  HKEY_CURRENT_USER;
end;
procedure TForm1.btn2Click(Sender: TObject);
begin
  Self.ReloadReg;
end;
procedure TForm1.Load(w:DWORD;Key:String);
var
  reg        : TRegistry;
  openResult : Boolean;
  today      : TDateTime;
  strings:TStringList;    i:integer;
  ValueName,ValueValue : String ;
  ValueType :  TRegDataType ;

HexStringOfBinaryValue : string;
BinaryValue : Array[0..2000] Of byte;
  aNumberOfBytes : integer;
begin
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := w;// HKEY_LOCAL_MACHINE;
  if (not reg.KeyExists(key)) then
  begin
    MessageDlg('Key not found!',mtInformation, mbOKCancel, 0);
    exit;
  end;
//  reg.Access := KEY_READ;
  openResult := reg.OpenKey(key,False);
  if not openResult then
    begin
      MessageDlg('Unable to create key! Exiting.',
                  mtError, mbOKCancel, 0);
      exit;
    end;

    strings:=TStringList.Create;
    reg.GetKeyNames(strings);
    for i := 0 to strings.Count -1 do
       ds2.AppendRecord([strings[i],'','KEY']);
    reg.GetValueNames(strings);
    for i := 0 to strings.Count -1 do begin
       ValueName := strings[i];
       ValueType := reg.GetDataType(ValueName);
       ValueValue :='';
       if ValueType = rdString then begin
          ValueValue :=      reg.ReadString(strings[i])
       end
       else  if ValueType = rdInteger then
          ValueValue :=      inttostr(reg.readInteger(strings[i]))
       else  if ValueType = rdExpandString then
          ValueValue :=      (reg.readString(strings[i]))
       else if ValueType = rdBinary then begin
           // if buffer size is less than the actually content size ,then cause error type .not "error size".be careful
           try
           aNumberOfBytes := reg.ReadBinaryData(ValueName,BinaryValue,SizeOf(BinaryValue));
           HexStringOfBinaryValue := ConvertBinerToHex(BinaryValue, aNumberOfBytes);
           valuevalue := HexStringOfBinaryValue;
           except
             ShowMessage('binary buffer must be small');
           end;
       end;
       ds2.AppendRecord([ValueName,    valuevalue  ,Tostr(ValueType)]);
    end;
    strings.free;
  reg.CloseKey();
  reg.Free;

end;
procedure TForm1.NavigateDown(path:string);
begin
  edt1.Text := edt1.text +path  +'\';
  reloadReg;
end;
procedure TForm1.dbgrd1DblClick(Sender: TObject);
begin
  if ds2.FieldByName('type').asstring ='KEY' then
     NavigateDown(  ds2.fieldbyName('name').asstring);


end;

//How to get path to the parent folder of a certain directory?
function up(str:string):string;
begin
  result := ExtractFilePath(ExcludeTrailingPathDelimiter(str));
end;
procedure TForm1.btnUpClick(Sender: TObject);
begin
  assert(up('Software\MyCompanyName\MyApplication\')='Software\MyCompanyName\')    ;
  edt1.Text := up(edt1.Text);
  btn2Click(nil);
end;

procedure TForm1.btnRootClick(Sender: TObject);
begin
  edt1.Text := '';
  btn2Click(nil);
end;
procedure AddKey(w:DWORD;NewKeyName:String);
var
  reg        : TRegistry;
  openResult : Boolean;
  today      : TDateTime;
  strings:TStringList;    i:integer;
  ValueName,ValueValue : String ;
  ValueType :  TRegDataType ;

HexStringOfBinaryValue : string;
BinaryValue : Array[0..200] Of byte;
  aNumberOfBytes : integer;
begin
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := w;
  if (reg.KeyExists(NewKeyName)) then
  begin
    MessageDlg('Key Exists!',mtInformation, mbOKCancel, 0);
    exit;
  end;
  openResult := reg.CreateKey(NewKeyName);
  if not openResult then
    begin
      MessageDlg('Unable to create key! Exiting.',
                  mtError, mbOKCancel, 0);
      exit;
    end;
  reg.Free;
end;


procedure TForm1.btnAddClick(Sender: TObject);
var k : string;
begin
  k := KeyNameForm.GetKeyName;
  if k <>'' then begin
    AddKey(toHk(cbb1.Items[cbb1.itemIndex]),IncludeTrailingPathDelimiter(edt1.Text)+k);
    btn2Click(nil);
  end;
end;
procedure del(w:DWORD;key:string);
var
  reg        : TRegistry;
  openResult : Boolean;
  today      : TDateTime;
  strings:TStringList;    i:integer;
  ValueName,ValueValue : String ;
  ValueType :  TRegDataType ;

HexStringOfBinaryValue : string;
BinaryValue : Array[0..200] Of byte;
  aNumberOfBytes : integer;
begin
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := w;// HKEY_LOCAL_MACHINE;
  if (not reg.KeyExists(key)) then
  begin
    MessageDlg('Key not found!',mtInformation, mbOKCancel, 0);
    exit;
  end;
    reg.DeleteKey(Key);
  reg.Free;

end;
procedure TForm1.btnDelClick(Sender: TObject);
begin
    del(toHK(edt1.Text),IncludeTrailingPathDelimiter(edt1.Text)+ds2.FieldValues['name']);
    btn2click(nil)
end;
procedure   changeKeyName(w:DWORD;key,newName:string);
var
  reg        : TRegistry;
  openResult : Boolean;
  today      : TDateTime;
  strings:TStringList;    i:integer;
  NewKey,ValueName,ValueValue : String ;
  ValueType :  TRegDataType ;

begin
  reg := TRegistry.Create(KEY_ALL_ACCESS);
  reg.RootKey := w;// HKEY_LOCAL_MACHINE;
//  if (not reg.KeyExists(key)) then
//  begin
//    MessageDlg('Key not found!',mtInformation, mbOKCancel, 0);
//    exit;
//  end;
//  reg.Access := KEY_READ;
//  openResult := reg.OpenKey(key,False);
//  if not openResult then
//    begin
//      MessageDlg('Unable to create key! Exiting.',
//                  mtError, mbOKCancel, 0);
//      exit;
//    end;
//    reg.RenameValue();
  newKey := IncludeTrailingPathDelimiter(up(key))+newName;
//  assert(reg.KeyExists(newkey)=false);
  reg.MoveKey(key,newKey,true);
//  reg.CloseKey();
  reg.Free;

end;
procedure TForm1.btnEditClick(Sender: TObject);
var o : string;
begin
  o := ds2.FieldValues['name'];
  o := KeyNameForm.GetKeyName(o);
  changeKeyName(toHk(cbb1.Items[cbb1.itemIndex]),IncludeTrailingPathDelimiter(edt1.Text)+ds2.FieldValues['name'],o);
//   Load(toHk(cbb1.Items[cbb1.itemIndex]),edt1.Text);
   btn2Click(nil)
end;
procedure TForm1.ReloadReg;
begin
   self.ds2.EmptyDataSet;
   Load(toHk(cbb1.Items[cbb1.itemIndex]),edt1.Text);
   self.ds2.First;
end;
procedure TForm1.cbb1Change(Sender: TObject);
begin
  self.edt1.Text := '';
  ReloadReg;
end;

procedure TForm1.edt1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
//  if (key =#13)then
//    self.ReloadReg;
end;

procedure TForm1.edt1KeyPress(Sender: TObject; var Key: Char);
begin
  if (Key ='/') then
    Key := '\'
  else if (Key = #13) then
    self.ReloadReg;
end;

procedure TForm1.dbgrd1KeyPress(Sender: TObject; var Key: Char);
begin
//  if (Key =  #13) then
//    self.NavigateDown(ds2.fieldbyName('name').asstring);
end;

procedure TForm1.dbgrd1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN)then begin
    if ds2.FieldByName('type').asstring ='KEY' then
      self.NavigateDown(ds2.fieldbyName('name').asstring)  end
  else if (Key = VK_Back) then begin
    edt1.Text := up(edt1.Text);
    btn2Click(nil);
  end;
      
end;

procedure TForm1.btnTestClick(Sender: TObject);
var ds2 : MemTable;
begin
    ds2 := MemTable.Create(nil);
    ds2.FieldDefs.Add('Name',  ftString, 250, False);
  ds2.FieldDefs.Add('Value', ftString,  250, False);
  ds2.FieldDefs.Add('Type',  ftString,   250, False);// Key,Reg_String...
//  ds2.CreateDataSet;
  ds2.CreateTable;
  ds2.Open;
  ds2.Fields[0].DisplayWidth := 25 ;
    ds2.Fields[1].DisplayWidth := 25 ;
      ds2.Fields[2].DisplayWidth := 25 ;
  ds2.AppendRecord(['key','KeyName','KEY']);
  ds2.AppendRecord(['VALUE','VALUE','Reg_String']);
end;

end.
