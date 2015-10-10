unit AliasOfSys;

interface
uses HKMTab;
type
   MemTable = class(THKMemTab)
   public
     procedure EmptyDataSet;
     procedure CreateDataSet;
   end;
implementation

{ MemTable }

procedure MemTable.CreateDataSet;
begin
  self.CreateTable;
end;

procedure MemTable.EmptyDataSet;
begin
  self.DeleteAll ;
end;

end.
