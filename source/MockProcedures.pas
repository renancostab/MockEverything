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
Original Code: MockProcedures.pas

***************************************************************************************************)

unit MockProcedures;

interface

uses
  SysUtils, Variants, Generics.Collections, Rtti, TypInfo, MockCommon;

type
  TMockRecord = record
  end;

  TMock = (mockSet1, mockSet2);
  TMockSet = set of TMock;

  procedure MockNoReturn(const AObject);
  procedure MockDestroy(const AObject: TObject);

  function MockCreate(const AClass: Pointer; ARef: Integer; AParam1: Integer): Pointer;
  function MockString(const AObject): string;
  function MockChar(const AObject): Char;
  function MockInteger(const AObject): Integer;
  function MockInt64(const AObject): Int64;
  function MockBoolean(const AObject): Boolean;
  function MockPointer(const AObject): Pointer;
  function MockFloat(const AObject): Double;
  function MockObject(const AObject): TObject;
  function MockArray(const AObject): TArray<Pointer>;
  function MockRecord(const AObject): TMockRecord;
  function MockAnsiChar(const AObject): AnsiChar;
  function MockAnsiString(const AObject): AnsiString;
  function MockClassRef(const AObject): TClass;
  function MockSet(const AObject): TMockSet;
  function MockVariant(const AObject): Variant;


const
  MOCKPROCEDURE: array [tkUnknown..tkProcedure] of Pointer = (nil,
                                                              @MockInteger,
                                                              @MockAnsiChar,
                                                              @MockBoolean,
                                                              @MockFloat,
                                                              @MockString,
                                                              @MockSet,
                                                              @MockObject,
                                                              @MockPointer,
                                                              @MockChar,
                                                              @MockAnsiString,
                                                              @MockString,
                                                              @MockVariant,
                                                              @MockArray,
                                                              @MockRecord,
                                                              @MockObject,
                                                              @MockInt64,
                                                              @MockArray,
                                                              @MockString,
                                                              @MockClassRef,
                                                              @MockPointer,
                                                              @MockPointer);

var
  GlobalHookList: TDictionary<Pointer, TDictionary<THookType, Pointer>>;

implementation

procedure CreateGlobalList;
begin
  GlobalHookList := TDictionary<Pointer, TDictionary<THookType, Pointer>>.Create;
end;

procedure DestroyGlobalList;
var
  Dict: Pointer;
begin
  for Dict in GlobalHookList.Keys do
    GlobalHookList.Items[Dict].Free;

  GlobalHookList.Free;
end;

procedure MockNoReturn(const AObject);
begin
  Exit;
end;

procedure MockDestroy(const AObject: TObject);
begin
  if GlobalHookList.ContainsKey(AObject.ClassType) then
  begin
    if GlobalHookList[AObject.ClassType].ContainsKey(htDestructor) then
      TInstanceHook(GlobalHookList[AObject.ClassType].Items[htDestructor])(AObject);
  end;

  AObject.FreeInstance;
end;

function MockCreate(const AClass: Pointer; ARef: Integer; AParam1: Integer): Pointer;
var
  Proc: Pointer;
  Size: Integer;
begin
  asm
    mov eax, esp
    mov edx, ebp
    mov esp, ebp
    pop ebp
    mov ecx, ebp
    push ebp
    mov esp, eax
    mov ebp, edx
    sub ecx, edx
    sub ecx, 20
    mov Size, ecx
  end;

  Result := TClass(AClass).NewInstance;
  if not GlobalHookList.ContainsKey(AClass) then
    Exit;

  if not GlobalHookList[AClass].ContainsKey(htCreate) then
    Exit;

  Proc := GlobalHookList[AClass].Items[htCreate];
  asm
    mov ecx, Size
    test ecx, ecx
    jz @@SKIP
    sub ecx, 4
    mov eax, [ebp + $8 + ecx]
    jz @@SKIP
    @@LOOP:
      sub ecx, 4
      push [ebp + $8 + ecx]
    jnz @@LOOP
    @@SKIP:
    mov ecx, eax
    mov eax, Result
    mov edx, AParam1
    call Proc
  end;
end;

function MockString(const AObject): string;
begin
  Result := EmptyStr;
end;

function MockChar(const AObject): Char;
begin
  Result := #0;
end;

function MockInteger(const AObject): Integer;
begin
  Result := 0;
end;

function MockInt64(const AObject): Int64;
begin
  Result := 0;
end;

function MockBoolean(const AObject): Boolean;
begin
  Result := True;
end;

function MockPointer(const AObject): Pointer;
begin
  Result := nil;
end;

function MockFloat(const AObject): Double;
begin
  Result := 0;
end;

function MockObject(const AObject): TObject;
begin
  Result := nil;
end;

function MockArray(const AObject): TArray<Pointer>;
begin
  SetLength(Result, 0);
end;

function MockRecord(const AObject): TMockRecord;
begin
  Exit;
end;

function MockAnsiChar(const AObject): AnsiChar;
begin
  Result := #0;
end;

function MockAnsiString(const AObject): AnsiString;
begin
  Result := EmptyAnsiStr;
end;

function MockClassRef(const AObject): TClass;
begin
  Result := TObject.ClassParent;
end;

function MockSet(const AObject): TMockSet;
begin
  Result := [];
end;

function MockVariant(const AObject): Variant;
begin
  Result := Null;
end;

initialization
  CreateGlobalList;

finalization
  DestroyGlobalList;

end.
