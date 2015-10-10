

unit HKMTab;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db;

const MTMaxRec: integer=10000;              //Record-Limit

type
  MTError=class(Exception);

  PRecInfo=^TMTRecInfo;
  TMTRecInfo=record
    Bookmark: Longint;
    BookmarkFlag: TBookmarkFlag;
  end;

  pInteger=^Integer;
  pSmallInt=^SmallInt;
  pFloat=^Extended;
  pBoolean=^Boolean;


  THKMemTab=class(TDataSet)
  private
   FStream: TMemoryStream;
   FWorkStream: TMemoryStream;           //Needed for Delete
   FRecInfoOffset: integer;
   FRecInfoSize: integer;
   FRecCount: integer;
   FRecSize: integer;
   FRecBufferSize: integer;
   FCurrRecNo: integer;
   FIsOpen: boolean;
   FFilterBuffer: PChar;
  protected
   //Abstract Overrides
   function  AllocRecordBuffer: PChar; override;
   procedure FreeRecordBuffer(var Buffer: PChar); override;
   procedure GetBookmarkData(Buffer: PChar; Data: Pointer); override;
   function  GetBookmarkFlag(Buffer: PChar): TBookmarkFlag; override;
   function  GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
   function  GetRecord(Buffer: PChar; GetMode: TGetMode; DoCheck: Boolean): TGetResult; override;
   function  GetRecordSize: Word; override;
   procedure InternalAddRecord(Buffer: Pointer; Append: Boolean); override;
   procedure InternalClose; override;
   procedure InternalDelete; override;
   procedure InternalFirst; override;
   procedure InternalGotoBookmark(Bookmark: Pointer); override;
   procedure InternalHandleException; override;
   procedure InternalInitFieldDefs; override;
   procedure InternalInitRecord(Buffer: PChar); override;
   procedure InternalLast; override;
   procedure InternalOpen; override;
   procedure InternalPost; override;
   procedure InternalSetToRecord(Buffer: PChar); override;
   function  IsCursorOpen: Boolean; override;
   procedure SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag); override;
   procedure SetBookmarkData(Buffer: PChar; Data: Pointer); override;
   procedure SetFieldData(Field: TField; Buffer: Pointer); override;

   //Optional Overrides
   function GetRecordCount: Integer; override;
   procedure SetRecNo(Value: Integer); override;
   function GetRecNo: Integer; override;

  private
    { Private-Deklarationen }
   function  MTGetRecStreamPos(RecNo: integer): longint;
   function  MTGetFieldOffset(FieldNo: integer): integer;
   function  MTGetFieldSize(FieldNo: integer): integer;
   function  MTGetActiveBuffer(var Buffer: PChar): Boolean;
   procedure MTReadRecord(Buffer:PChar;RecNo:Integer);
   procedure MTWriteRecord(Buffer:PChar;RecNo:Integer);
   procedure MTAppendRecord(Buffer:PChar);
   function  MTFilterRecord(Buffer: PChar): Boolean;

  protected
    { Protected-Deklarationen }

  public
    { Public-Deklarationen }
   constructor Create(AOwner:tComponent); override;
   destructor Destroy; override;
   procedure CreateTable;
   function GetUsedStreamMem: longint;
   procedure DeleteAll;

  published
    { Published-Deklarationen }
   property Filtered;
   property BeforeOpen;
   property AfterOpen;
   property BeforeClose;
   property AfterClose;
   property BeforeInsert;
   property AfterInsert;
   property BeforeEdit;
   property AfterEdit;
   property BeforePost;
   property AfterPost;
   property BeforeCancel;
   property AfterCancel;
   property BeforeDelete;
   property AfterDelete;
   property BeforeScroll;
   property AfterScroll;
   property OnDeleteError;
   property OnEditError;
   property OnNewRecord;
   property OnPostError;
   property OnFilterRecord;
  end;

procedure Register;

implementation

procedure Register;
begin
 RegisterComponents('HKComps', [THKMemTab]);
end;
// Create and Destroy
constructor THKMemTab.Create(AOwner:tComponent);
begin
 inherited create(aOwner);
 FStream:=TMemoryStream.Create;
 FWorkStream:=TMemoryStream.Create;
 FRecInfoSize:=SizeOf(TMTRecInfo);
 FRecCount:=0;
 FRecSize:=0;
 FRecBufferSize:=0;
 FRecInfoOffset:=0;
 FCurrRecNo:=-1;
 FIsOpen:=False;
end;

destructor THKMemTab.Destroy;
begin
 FStream.Free;
 FWorkStream.Free;
 inherited Destroy;
end;

//Private Helping-Procs and Funcs
function THKMemTab.MTGetRecStreamPos(RecNo: integer): longint;   //Results the Stream-Offset of the curr. Rec
begin
 result:=FRecSize*RecNo
end;

function THKMemTab.MTGetFieldOffset(FieldNo: integer): integer;   //Results the requested Field-Offset
var x: integer;
    offs : integer;
begin
 offs:=0;
 if FieldNo>1 then
 begin
  for x:=1 to FieldNo-1 do
  begin
   offs:=offs+MTGetFieldSize(x);
  end;
 end;
 result:=offs;
end;

function THKMemTab.MTGetFieldSize(FieldNo: integer): integer;   //Results the FieldSize of requested Field
begin
 case FieldDefs.Items[FieldNo-1].Datatype of
  ftString:   result:=FieldDefs.Items[FieldNo-1].Size+1;
  ftBoolean:  result:=2;
  ftFloat:    result:=10;
  ftSmallInt: result:=2;
  ftInteger:  result:=4;
  ftDate:     result:=10;
  ftTime:     result:=10;
 else begin
  raise MTError.Create('Fieldtype of Field "'+FieldDefs.Items[FieldNo-1].Name+'" not supported!');
 end;
 end;
end;

function THKMemTab.MTGetActiveBuffer(var Buffer: PChar): Boolean;   //Checks the State and Results a defined Buffer;
begin
 case State of
  dsBrowse:
   if IsEmpty then Buffer:=nil
   else	Buffer := ActiveBuffer;

  dsEdit, dsInsert: Buffer:=ActiveBuffer;
  dsFilter:         Buffer:=FFilterBuffer;

 else Buffer:=nil;
 end;
 result:=Buffer<>nil;
end;

//Private
procedure THKMemTab.MTReadRecord(Buffer:PChar;RecNo:Integer);   //Reads a Rec from Stream in Buffer
begin
 FStream.Position:=MTGetRecStreamPos(RecNo);
 FStream.ReadBuffer(Buffer^, FRecSize);
end;

procedure THKMemTab.MTWriteRecord(Buffer:PChar;RecNo:Integer);  //Writes a Rec from Buffer to Stream
begin
 FStream.Position:=MTGetRecStreamPos(RecNo);
 FStream.WriteBuffer(Buffer^, FRecSize);
end;

procedure THKMemTab.MTAppendRecord(Buffer:PChar);   //Appends a Rec (from Buffer) to Stream
begin
 FStream.Position:=MTGetRecStreamPos(FRecCount);
 FStream.WriteBuffer(Buffer^, FRecSize);
end;

//Abstract Ovverides
function THKMemTab.AllocRecordBuffer: PChar;
begin
 result:=StrAlloc(FRecBufferSize);
end;

procedure THKMemTab.FreeRecordBuffer (var Buffer: PChar);
begin
 StrDispose(Buffer);
end;

procedure THKMemTab.InternalInitRecord(Buffer: PChar);
var x: integer;
begin
 for x:=0 to FieldCount-1 do
 begin
  case FieldDefs.Items[x].Datatype of
   ftString:   pChar(Buffer+MTGetFieldOffset(x+1))^:=#0;
   ftBoolean:  pBoolean(Buffer+MTGetFieldOffset(x+1))^:=False;
   ftFloat:    pFloat(Buffer+MTGetFieldOffset(x+1))^:=0;
   ftSmallInt: pSmallInt(Buffer+MTGetFieldOffset(x+1))^:=0;
   ftInteger:  pInteger(Buffer+MTGetFieldOffset(x+1))^:=0;
   ftCurrency: pFloat(Buffer+MTGetFieldOffset(x+1))^:=0;
   ftDate:     pFloat(Buffer+MTGetFieldOffset(x+1))^:=0;
   ftTime:     pFloat(Buffer+MTGetFieldOffset(x+1))^:=0;
   ftDateTime: pFloat(Buffer+MTGetFieldOffset(x+1))^:=0;
  end;
 end;
end;

procedure THKMemTab.InternalDelete;
begin
 if (FCurrRecNo>=0) and (FCurrRecNo<FRecCount) then
 begin
  if FCurrRecNo>0 then
  begin
   if FCurrRecNo<FRecCount-1 then
   begin
    FStream.Position:=MTGetRecStreamPos(0);      //Delete Rec
    FWorkStream.Clear;
    FWorkStream.CopyFrom(FStream, MTGetRecStreamPos(FCurrRecNo)-MTGetRecStreamPos(0));
    FStream.Position:=MTGetRecStreamPos(FCurrRecNo+1);
    FWorkStream.CopyFrom(FStream,(MTGetRecStreamPos(FRecCount))-MTGetRecStreamPos(FCurrRecNo+1));
    FStream.LoadFromStream(FWorkStream);
    FWorkStream.Clear;
   end
   else begin
    FStream.Position:=MTGetRecStreamPos(0);     //Delete last Rec
    FWorkStream.Clear;
    FWorkStream.CopyFrom(FStream,MTGetRecStreamPos(FRecCount-1));
    FStream.LoadFromStream(FWorkStream);
    FWorkStream.Clear;
   end;
  end
  else begin                                  //Delete first Rec
   FStream.Position:=MTGetRecStreamPos(FCurrRecNo+1);
   FWorkStream.Clear;
   FWorkStream.CopyFrom(FStream,(MTGetRecStreamPos(FRecCount))-MTGetRecStreamPos(FCurrRecNo+1));
   FStream.LoadFromStream(FWorkStream);
   FWorkStream.Clear;
  end;
  dec(FRecCount);
  if FRecCount=0 then FCurrRecNo:=-1
  else
   if FCurrRecNo>=FRecCount then FCurrRecNo:=FRecCount-1;
 end;
end;

procedure THKMemTab.InternalInitFieldDefs;
begin
 //not used yet
end;

procedure THKMemTab.InternalFirst;
begin
 FCurrRecNo:=-1;
end;

procedure THKMemTab.InternalLast;
begin
 FCurrRecNo:=FRecCount;
end;

procedure THKMemTab.InternalOpen;
begin
 InternalInitFieldDefs;
 if DefaultFields then CreateFields;
 BindFields(True);
 FCurrRecNo:=-1;
 FIsOpen:=True;
end;

procedure THKMemTab.InternalClose;
begin
 FIsOpen:=False;
 BindFields(False);
 if DefaultFields then DestroyFields;
end;

procedure THKMemTab.InternalPost;
begin
 CheckActive;
 if ((State<>dsEdit) and (State<>dsInsert)) then Exit;
 if State=dsEdit then MTWriteRecord(ActiveBuffer, FCurrRecNo)
  else InternalAddRecord(ActiveBuffer,True);

end;

function THKMemTab.IsCursorOpen: Boolean;
begin
 result:=FIsOpen;
end;

function THKMemTab.GetRecord(Buffer: PChar; GetMode: TGetMode; DoCheck: Boolean): TGetResult;
var Acceptable: Boolean;
begin
 result:=grOk;
 Acceptable:=False;
 if FRecCount<1 then
  result:=grEOF
 else begin
  repeat
   case GetMode of
    gmCurrent:
    begin
     if (FCurrRecNo>=FRecCount) or (FCurrRecNo<0) then result:=grError;
    end;

    gmNext:
    begin
     if FCurrRecNo<FRecCount-1 then Inc(FCurrRecNo)
     else result:=grEOF;
    end;

    gmPrior:
    begin
     if FCurrRecNo>0 then Dec(FCurrRecNo)
     else result:=grBOF;
    end;
   end; {case of}

  if result=grOK then
  begin
   MTReadRecord(Buffer, FCurrRecNo);
   PRecInfo(Buffer+FRecInfoOffset)^.Bookmark:=FCurrRecNo;
   PRecInfo(Buffer+FRecInfoOffset)^.BookmarkFlag:=bfCurrent;
   if (Filtered) then Acceptable:=MTFilterRecord(Buffer) //Filtering
    else Acceptable:=True;
   if (GetMode=gmCurrent) and not Acceptable then result:=grError;
  end;
  until (result<>grOK) or Acceptable;
 end;
end;

function THKMemTab.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var SrcBuffer: PChar;
begin
 result:=False;
 if not MTGetActiveBuffer(SrcBuffer) then Exit;
 if (Field.FieldNo>0)and(Assigned(Buffer))and(Assigned(SrcBuffer)) then
 begin
  Move((SrcBuffer+MTGetFieldOffset(Field.FieldNo))^, Buffer^, MTGetFieldSize(Field.FieldNo));
  result:=True;
 end;
end;

procedure THKMemTab.SetFieldData(Field: TField; Buffer: Pointer);
var DestBuffer: PChar;
begin
 MTGetActiveBuffer(DestBuffer);
 if (Field.FieldNo>0)and(Assigned(Buffer))and(Assigned(DestBuffer)) then
 begin
  Move(Buffer^, (DestBuffer+MTGetFieldOffset(Field.FieldNo))^, MTGetFieldSize(Field.FieldNo));
 end;
end;

function THKMemTab.GetRecordSize: Word;
begin
 result:=FRecSize;
end;

procedure THKMemTab.InternalGotoBookmark(Bookmark: Pointer);
var ReqBookmark: integer;
begin
 ReqBookmark:=PInteger(Bookmark)^;
 if (ReqBookmark>=0) and (ReqBookmark<FRecCount) then FCurrRecNo:=ReqBookmark
  else raise MTError.Create('Bookmark '+IntToStr(ReqBookmark)+' not found!');
end;

procedure THKMemTab.InternalSetToRecord(Buffer: PChar);
var ReqBookmark: integer;
begin
 ReqBookmark:=PRecInfo(Buffer+FRecInfoOffset).Bookmark;
 InternalGotoBookmark (@ReqBookmark);
end;

function THKMemTab.GetBookmarkFlag(Buffer: PChar): TBookmarkFlag;
begin
 result:=PRecInfo(Buffer+FRecInfoOffset)^.BookmarkFlag;
end;

procedure THKMemTab.SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag);
begin
 PRecInfo(Buffer+FRecInfoOffset)^.BookmarkFlag := Value;
end;

procedure THKMemTab.GetBookmarkData(Buffer: PChar; Data: Pointer);
begin
 if Data<>nil then PInteger(Data)^:=PRecInfo(Buffer+FRecInfoOffset)^.Bookmark;
end;

procedure THKMemTab.SetBookmarkData(Buffer: PChar; Data: Pointer);
begin
 if Data<>nil then PRecInfo(Buffer+FRecInfoOffset)^.Bookmark:=PInteger(Data)^
  else PRecInfo(Buffer+FRecInfoOffset)^.Bookmark:=0;
end;

function THKMemTab.MTFilterRecord(Buffer: PChar): Boolean;
var SaveState: TDatasetState;
begin
 result:=True;
 if not Assigned(OnFilterRecord) then Exit;
 SaveState:=SetTempState(dsFilter);
 FFilterBuffer:=Buffer;
 OnFilterRecord(self,result);
 RestoreState(SaveState);
end;

function THKMemTab.GetUsedStreamMem: longint;
begin
 result:=FStream.Size;
end;

procedure THKMemTab.InternalHandleException;
begin
 Application.HandleException(Self);
end;

procedure THKMemTab.DeleteAll;
begin
 FStream.Clear;
 FRecCount:=0;
 FCurrRecNo:=-1;
 Resync([]);
end;

procedure THKMemTab.CreateTable;
var x: integer;
begin
 FStream.Clear;
 FRecCount:=0;
 FCurrRecNo:=-1;
 FIsOpen:=False;
 FRecSize:=0;

 if FieldDefs.Count>0 then
 begin
  for x:=0 to FieldDefs.Count-1 do
  begin
   FRecSize:=FRecSize+MTGetFieldSize(x+1);
  end;
 end;
 FRecInfoOffset:=FRecSize;
 FRecSize:=FRecSize+FRecInfoSize;
 FRecBufferSize:=FRecSize;
end;

procedure THKMemTab.InternalAddRecord(Buffer: Pointer; Append: Boolean);
begin
 if FRecCount>=MTMaxRec then raise MTError.Create('Record-Limitation ('+IntToStr(MTMaxRec)+') active!')
 else begin
  MTAppendRecord(ActiveBuffer);
  InternalLast;
  Inc(FRecCount);
 end;
end;

procedure THKMemTab.SetRecNo(Value: Integer);
begin
 CheckBrowseMode;
 if (Value>1) and (Value<=FRecCount) then
 begin
  FCurrRecNo:=Value-1;
  Resync([]);
 end;
end;

function THKMemTab.GetRecNo: Longint;
begin
 UpdateCursorPos;
 if FCurrRecNo<0 then Result:=1
  else Result:=FCurrRecNo+1;
end;

function THKMemTab.GetRecordCount: Longint;
begin
 CheckActive;
 Result:=FRecCount;
end;

end.


