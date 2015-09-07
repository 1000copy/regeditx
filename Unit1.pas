unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, DBClient, Grids, DBGrids, ExtCtrls;

type
  TForm1 = class(TForm)
    dbgrd1: TDBGrid;
    ds1: TDataSource;
    ds2: TClientDataSet;
    pnl1: TPanel;
    edt1: TEdit;
    btn1: TButton;
    btn2: TButton;
    cbb1: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure dbgrd1DblClick(Sender: TObject);
  private
    procedure Doit(w: DWORD; Key: String);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
uses registry;
{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
//  ds2.FieldDefs.Add('ID',      ftInteger, 0, False);
//  ds2.FieldDefs.Add('Status',  ftString, 10, False);
//  ds2.FieldDefs.Add('Created', ftDate,    0, False);
//  ds2.FieldDefs.Add('Volume',  ftFloat,   0, False);
  ds2.FieldDefs.Add('Name',  ftString, 250, False);
  ds2.FieldDefs.Add('Value', ftString,  250, False);
  ds2.FieldDefs.Add('Type',  ftString,   250, False);// Key,Reg_String...
  ds2.CreateDataSet;
  ds2.Fields[0].DisplayWidth := 25 ;
    ds2.Fields[1].DisplayWidth := 25 ;
      ds2.Fields[2].DisplayWidth := 25 ;
//  ds2.AppendRecord(['key','KeyName','KEY']);
//  ds2.AppendRecord(['VALUE','VALUE','Reg_String']);
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
  if s = 'HKEY_CLASSES_ROOT' then
   result := HKEY_CLASSES_ROOT
  else if s = 'HKEY_CURRENT_USER' then result := HKEY_CURRENT_USER
  else if s=  'HKEY_LOCAL_MACHINE' then result := HKEY_LOCAL_MACHINE
    else if s=  'HKEY_USERS' then result := HKEY_USERS
      else if s=  'HKEY_PERFORMANCE_DATA' then result := HKEY_PERFORMANCE_DATA
        else if s=  'HKEY_CURRENT_CONFIG' then result := HKEY_CURRENT_CONFIG
          else if s=  'HKEY_DYN_DATA' then result := HKEY_DYN_DATA;
  result :=  HKEY_CURRENT_USER;
end;
procedure TForm1.btn2Click(Sender: TObject);
begin
   self.ds2.EmptyDataSet;
      doIt(toHk(cbb1.Items[cbb1.itemIndex]),edt1.Text);

end;
procedure TForm1.Doit(w:DWORD;Key:String);
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
           aNumberOfBytes := reg.ReadBinaryData(ValueName,BinaryValue,SizeOf(BinaryValue));
           HexStringOfBinaryValue := ConvertBinerToHex(BinaryValue, aNumberOfBytes);
           valuevalue := HexStringOfBinaryValue;
       end;
       ds2.AppendRecord([ValueName,    valuevalue  ,Tostr(ValueType)]);
    end;
    strings.free;
  reg.CloseKey();
  reg.Free;

end;

procedure TForm1.dbgrd1DblClick(Sender: TObject);
begin
         if ds2.FieldByName('type').asstring ='KEY' then
    edt1.Text := edt1.text + ds2.fieldbyName('name').asstring +'\';
  btn2.Click;
end;

end.
