unit ClassTest;

interface

uses
  SysUtils, Generics.Collections, Dialogs;

type
  TClassTest = class(TObject)
  private
    FList: TList<Integer>;

    procedure PrivateProc;
  protected
    procedure ProtectedProc;
  public
    constructor Create;
    destructor Destroy; override;

    function Sum(A, B: Integer): Integer;
    procedure CallPrivate;
    procedure CallProtected;
  end;

implementation

procedure TClassTest.CallPrivate;
begin
  PrivateProc;
end;

procedure TClassTest.CallProtected;
begin
  ProtectedProc;
end;

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

procedure TClassTest.PrivateProc;
begin
  ShowMessage('Private');
end;

procedure TClassTest.ProtectedProc;
begin
  ShowMessage('Protected');
end;

function TClassTest.Sum(A, B: Integer): Integer;
begin
  Result := A + B;
  FList.Add(Result);
end;

end.
