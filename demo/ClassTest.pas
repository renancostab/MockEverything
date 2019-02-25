unit ClassTest;

interface

uses
  System.SysUtils, Generics.Collections, Vcl.Dialogs;

type
  TClassTest = class(TObject)
  private
    FList: TList<Integer>;
  public
    constructor Create;
    destructor Destroy; override;

    function Sum(A, B: Integer): Integer;
  end;

implementation

constructor TClassTest.Create;
begin
  ShowMessage('Create');
  FList := TList<Integer>.Create;
end;

destructor TClassTest.Destroy;
begin
  ShowMessage('Destroy');
  FList.Free;
  inherited;
end;

function TClassTest.Sum(A, B: Integer): Integer;
begin
  Result := A + B;
  FList.Add(Result);
end;

end.
