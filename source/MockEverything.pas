(**************************************************************************************************
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
ANY KIND, either express or implied. See the License for the specific language governing rights
and limitations under the License.

Project......: Mock Everything
Author.......: Renan Bellódi
Company......: Softplan ®
Original Code: MockEverything.pas

***************************************************************************************************)

unit MockEverything;

interface

uses
  SysUtils, Generics.Collections, Rtti, TypInfo, DDetours, MockProcedures, MockCommon, MockMap;

type
  TProcedure = procedure;
  TDetourPair = TPair<Pointer, Pointer>;
  TDetourList = TList<TDetourPair>;
  TDetourDict = TDictionary<TClass, TDetourList>;
  TDetourType = (dtCreate, dtDestructor);

  TMockDetour = class(TObject)
  strict private
    class var FMock: TMockDetour;
    FDict: TDetourDict;
    FList: TDetourList;
    FMap: TMapFile;

    procedure Add(AClass: TClass; ADetourPair: TDetourPair);
    procedure AddMock(AClass: TClass; AType: TDetourType);

    function FindList(AMethod: Pointer): Integer;
    function GetMethod(AClass: TClass; const AMethod: string; ADetour: Pointer): TArray<TDetourPair>;
  protected
    constructor Create;
    class procedure SingletonDestroy;
  public
    class function Get: TMockDetour;

    destructor Destroy; override;

    procedure AddHook(AClass: TClass; AHook: TInstanceHook; AHookType: THookType);
    procedure LoadMapAddress(const AFile: string);
    procedure Mock(AClass: TClass; const AMethod: string; ADetour: Pointer); overload;
    procedure Mock(AClass: TClass; const AMethod: string); overload;
    procedure Mock(AClass: TClass; AMethod: Pointer; ADetour: Pointer); overload;
    procedure Mock(AClass: TClass; AMethod: Pointer); overload;
    procedure Mock(AMethod: Pointer; ADetour: Pointer); overload;
    procedure MockConstructor(AClass: TClass; AHook: TInstanceHook); overload;
    procedure MockDestructor(AClass: TClass; AHook: TInstanceHook);
    procedure MockEverything(AClass: TClass);

    procedure Remove(AClass: TClass; const AMethod: string); overload;
    procedure Remove(AClass: TClass; AMethod: Pointer); overload;
    procedure Remove(AMethod: Pointer); overload;
    procedure Restore(AClass: TClass);
    procedure Replace(AClass: TClass; const AMethod: string; ADetour: Pointer); overload;
    procedure Replace(AMethod: Pointer; ADetour: Pointer); overload;

    procedure RestoreClasses;
    procedure RestoreEverything;
    procedure RestoreFunctions;
  end;

implementation

procedure TMockDetour.Add(AClass: TClass; ADetourPair: TDetourPair);
begin
  if not FDict.ContainsKey(AClass) then
    FDict.AddOrSetValue(AClass, TList<TDetourPair>.Create);

  FDict[AClass].Add(ADetourPair);
end;

procedure TMockDetour.AddHook(AClass: TClass; AHook: TInstanceHook; AHookType: THookType);
begin
  if not GlobalHookList.ContainsKey(AClass) then
    GlobalHookList.Add(AClass, TDictionary<THookType, Pointer>.Create());

  GlobalHookList[AClass].AddOrSetValue(AHookType, @AHook);
end;

procedure TMockDetour.AddMock(AClass: TClass; AType: TDetourType);
var
  Context: TRttiContext;
  Method: TRttiMethod;
  Detour: Pointer;
begin
  if AType = dtCreate then
    Detour := @MockCreate
  else
    Detour := @MockDestroy;

  Context := TRttiContext.Create;
  for Method in Context.GetType(AClass.ClassInfo).GetDeclaredMethods do
  begin
    if AType = dtCreate then
    begin
      if not Method.IsConstructor then
        Continue;
    end
    else
    begin
      if not Method.IsDestructor then
        Continue;
    end;

    Add(AClass, TDetourPair.Create(Method.CodeAddress, InterceptCreate(Method.CodeAddress, Detour)));
  end;
  Context.Free;
end;

constructor TMockDetour.Create;
begin
  FDict := TDetourDict.Create;
  FList := TDetourList.Create;
  FMap := nil;
end;

{ TMockDetour }

destructor TMockDetour.Destroy;
begin
  RestoreEverything;
  FList.Free;
  FDict.Free;

  if Assigned(FMap) then
    FMap.Free;

  inherited;
end;

function TMockDetour.FindList(AMethod: Pointer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FList.Count - 1 do
  begin
    if FList[I].Key <> AMethod then
      Continue;

    Exit(I);
  end;
end;

class function TMockDetour.Get: TMockDetour;
begin
  if not Assigned(FMock) then
    FMock := TMockDetour.Create;

  Result := FMock;
end;

function TMockDetour.GetMethod(AClass: TClass; const AMethod: string; ADetour: Pointer): TArray<TDetourPair>;
var
  I: Integer;
  ListPointer: TArray<Pointer>;
  Context: TRttiContext;
  Method: TRttiMethod;
  Detour: Pointer;
begin
  if (Assigned(ADetour)) and (Assigned(FMap)) then
  begin
    ListPointer := FMap.GetMethods(AClass, AMethod);
    SetLength(Result, Length(ListPointer));

    for I := 0 to High(ListPointer) do
      Result[I] := TDetourPair.Create(ListPointer[I], ADetour);

    Exit;
  end;

  Context := TRttiContext.Create;
  for Method in Context.GetType(AClass.ClassInfo).GetDeclaredMethods do
  begin
    if not SameText(Method.Name, AMethod) then
      Continue;

    Detour := ADetour;
    if not Assigned(Detour) then
    begin
      if Assigned(Method.ReturnType) then
        Detour := MOCKPROCEDURE[Method.ReturnType.TypeKind]
      else
        Detour := @MockNoReturn;
    end;

    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := TDetourPair.Create(Method.CodeAddress, Detour);
  end;
  Context.Free;
end;

procedure TMockDetour.Mock(AClass: TClass; const AMethod: string; ADetour: Pointer);
var
  I: Integer;
  Methods: TArray<TDetourPair>;
begin
  Methods := GetMethod(AClass, AMethod, ADetour);
  if Length(Methods) = 0 then
    raise Exception.CreateFmt('Method [%s.%s] not found', [AClass.ClassName, AMethod]);

  for I := 0 to High(Methods) do
  begin
    if not Assigned(Methods[I].Value) then
      raise Exception.CreateFmt('Failed to assign a default mock method [%s.%s]', [AClass.ClassName, AMethod]);

    Add(AClass, TDetourPair.Create(Methods[I].Key, InterceptCreate(Methods[I].Key, Methods[I].Value)));
  end;
end;

procedure TMockDetour.Mock(AClass: TClass; const AMethod: string);
begin
  Mock(AClass, AMethod, nil);
end;

procedure TMockDetour.Mock(AClass: TClass; AMethod: Pointer);
begin
  Mock(AClass, AMethod, nil);
end;

procedure TMockDetour.Mock(AClass: TClass; AMethod, ADetour: Pointer);
var
  Context: TRttiContext;
  Method: TRttiMethod;
begin
  if not Assigned(AMethod) then
    raise Exception.Create('Method not assigned');

  if not Assigned(ADetour) then
  begin
    Context := TRttiContext.Create;
    for Method in Context.GetType(AClass.ClassInfo).GetDeclaredMethods do
    begin
      if Method.CodeAddress <> AMethod then
        Continue;

      if not Assigned(Method.ReturnType) then
        ADetour := MOCKPROCEDURE[Method.ReturnType.TypeKind]
      else
        ADetour := @MockNoReturn;

      Break;
    end;
    Context.Free;
  end;

  if not Assigned(ADetour) then
    raise Exception.Create('Failed to assign a default mock method');

  Add(AClass, TDetourPair.Create(AMethod, InterceptCreate(AMethod, ADetour)));
end;

procedure TMockDetour.MockConstructor(AClass: TClass; AHook: TInstanceHook);
begin
  AddMock(AClass, dtCreate);
  if Assigned(AHook) then
    AddHook(AClass, AHook, htCreate);
end;

procedure TMockDetour.MockDestructor(AClass: TClass; AHook: TInstanceHook);
begin
  AddMock(AClass, dtDestructor);
  if Assigned(AHook) then
    AddHook(AClass, AHook, htDestructor);
end;

procedure TMockDetour.MockEverything(AClass: TClass);
var
  Method: TRttiMethod;
  Context: TRttiContext;
  Detour: Pointer;
  Code: Cardinal;
begin
  Context := TRttiContext.Create;
  for Method in Context.GetType(AClass.ClassInfo).GetDeclaredMethods do
  begin
    if not Assigned(Method) then
      Continue;

    Code := (Integer(Method.IsConstructor) shl 2) or
            (Integer(Method.IsDestructor) shl 1) or
             Integer(Assigned(Method.ReturnType));

    case Code of
      0: Detour := @MockNoReturn;
      1: Detour := MOCKPROCEDURE[Method.ReturnType.TypeKind];
      2: Detour := @MockDestroy;
      4: Detour := @MockCreate;
    else
      Detour := nil;
    end;

    if not Assigned(Detour) then
      Continue;

    Add(AClass, TDetourPair.Create(Method.CodeAddress, InterceptCreate(Method.CodeAddress, Detour)));
  end;
  Context.Free;
end;

procedure TMockDetour.LoadMapAddress(const AFile: string);
begin
  if not FileExists(AFile) then
    raise Exception.CreateFmt('File not found [%s]', [AFile]);

  if Assigned(FMap) then
    FreeAndNil(FMap);

  FMap := TMapFile.Create(AFile);
  FMap.Parse;
end;

procedure TMockDetour.Remove(AClass: TClass; AMethod: Pointer);
var
  I: Integer;
  List: TDetourList;
begin
  if not FDict.ContainsKey(AClass) then
    Exit;

  List := FDict.Items[AClass];
  for I := 0 to List.Count - 1 do
  begin
    if List[I].Key <> AMethod then
      Continue;

    InterceptRemove(List[I].Value);
    List.Delete(I);
    Break;
  end;
end;

procedure TMockDetour.Replace(AMethod, ADetour: Pointer);
begin
  Remove(AMethod);
  Mock(AMethod, ADetour);
end;

procedure TMockDetour.Remove(AClass: TClass; const AMethod: string);
var
  I: Integer;
  Method: TRttiMethod;
  Context: TRttiContext;
  List: TDetourList;
begin
  if not FDict.ContainsKey(AClass) then
    Exit;

  List := FDict[AClass];
  Context := TRttiContext.Create;
  for Method in Context.GetType(AClass.ClassInfo).GetDeclaredMethods do
  begin
    if not SameText(Method.Name, AMethod) then
      Continue;

    for I := 0 to List.Count - 1 do
    begin
      if List[I].Key <> Method.CodeAddress then
        Continue;

      InterceptRemove(List[I].Value);
      List.Delete(I);
      Break;
    end;
  end;
  Context.Free;
end;

procedure TMockDetour.Replace(AClass: TClass; const AMethod: string; ADetour: Pointer);
begin
  Remove(AClass, AMethod);
  Mock(AClass, AMethod, ADetour);
end;

procedure TMockDetour.Restore(AClass: TClass);
var
  Key: TPair<TClass, TDetourList>;
  Pair: TDetourPair;
begin
  if not FDict.ContainsKey(AClass) then
    Exit;

  Key := FDict.ExtractPair(AClass);
  for Pair in Key.Value do
    InterceptRemove(Pair.Value);

  Key.Value.Free;
end;

procedure TMockDetour.RestoreClasses;
var
  ClassDetour: TPair<TClass, TList<TDetourPair>>;
  Pair: TDetourPair;
begin
  if FDict.Count = 0 then
    Exit;

  for ClassDetour in FDict do
  begin
    for Pair in ClassDetour.Value do
      InterceptRemove(Pair.Value);

    ClassDetour.Value.Free;
  end;
  FDict.Clear;
end;

procedure TMockDetour.RestoreEverything;
begin
  RestoreClasses;
  RestoreFunctions;
end;

procedure TMockDetour.RestoreFunctions;
var
  Pair: TDetourPair;
begin
  if FList.Count = 0 then
    Exit;

  for Pair in FList do
    InterceptRemove(Pair.Value);

  FList.Clear;
end;

class procedure TMockDetour.SingletonDestroy;
begin
  if Assigned(FMock) then
    FreeAndNil(FMock);
end;

procedure TMockDetour.Mock(AMethod, ADetour: Pointer);
begin
  FList.Add(TDetourPair.Create(AMethod, InterceptCreate(AMethod, ADetour)));
end;

procedure TMockDetour.Remove(AMethod: Pointer);
var
  Index: Integer;
begin
  Index := FindList(AMethod);
  if Index = -1 then
    Exit;

  InterceptRemove(FList[Index].Value);
  FList.Delete(Index);
end;

initialization

finalization
  TMockDetour.SingletonDestroy

end.

