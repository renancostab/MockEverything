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
Original Code: MockMap.pas

***************************************************************************************************)

unit MockMap;

interface

uses
  SysUtils, Classes, Rtti, Generics.Collections;

type
  TMapFile = class(TObject)
  private
    FMapFile: string;
    FHeader: array [1..6] of Integer;
    FDict: TDictionary<string, TList<Pointer>>;

    procedure ParseHeader(AMapFile: TStringList);
    procedure ParseAddress(AMapFile: TStringList);

    function StringInSet(const AValue: string; const ASet: array of string): Boolean;
    function StrSplit(const AValue: string; const ADelimiter: Char): TArray<string>;
  public
    constructor Create(const AFile: string);
    destructor Destroy; override;

    procedure Parse;

    function GetMethod(AClass: TClass; const AMethod: string): Pointer;
    function GetMethods(AClass: TClass; const AMethod: string): TArray<Pointer>;
  end;

implementation


{ TMapFile }

constructor TMapFile.Create(const AFile: string);
begin
  FMapFile := AFile;
  FillChar(FHeader[1], SizeOf(Integer) * Length(FHeader), 0);
  FDict := TDictionary<string, TList<Pointer>>.Create(1 shl 16);
end;

destructor TMapFile.Destroy;
var
  Pair: TPair<string, TList<Pointer>>;
begin
  if FDict.Count > 0 then
  begin
    for Pair in FDict do
      Pair.Value.Free;
  end;

  FDict.Free;
  inherited;
end;

function TMapFile.GetMethod(AClass: TClass; const AMethod: string): Pointer;
var
  Methods: TArray<Pointer>;
begin
  Result := nil;
  Methods := GetMethods(AClass, AMethod);
  if Length(Methods) > 0 then
    Result := Methods[0];
end;

function TMapFile.GetMethods(AClass: TClass; const AMethod: string): TArray<Pointer>;
var
  Key: string;
begin
  Key := Format('%s.%s.%s', [AClass.UnitName, AClass.ClassName, AMethod]);
  if FDict.ContainsKey(Key) then
    Result := FDict[Key].ToArray;
end;

procedure TMapFile.Parse;
var
  Map: TStringList;
begin
  Map := TStringList.Create;

  try
    try
      Map.LoadFromFile(FMapFile);
      ParseHeader(Map);
      ParseAddress(Map);
    except
      on E: Exception do
        raise Exception.CreateFmt('Failed to parse the map address %s [%s]', [sLineBreak, E.Message]);
    end;
  finally
    Map.Free;
  end;
end;

procedure TMapFile.ParseAddress(AMapFile: TStringList);
const
  IGNORE: array [0..11] of string = ('System',
                                     'Vcl',
                                     'WinApi',
                                     'FireDac',
                                     'Bde',
                                     'Data',
                                     'Datasnap',
                                     'Rest',
                                     'FMX',
                                     'IBX',
                                     'Xml',
                                     'SysInit');
var
  Start, Code, Base, Indx: Integer;
  Address: Pointer;
  Name, Line: string;
  List: TList<Pointer>;
begin
  Start := 0;
  while Trim(AMapFile[Start]) <> EmptyStr do
    Inc(Start);

  Inc(Start, 4);
  while True do
  begin
    while AMapFile[Start] <> EmptyStr do
    begin
      Line := AMapFile[Start];
      Inc(Start);

      Indx := Pos(':', Line);
      Code := StrToInt(Trim(Copy(Line, 1, Indx - 1)));

      if Code <> 1 then
        Continue;

      Base := StrToInt('$' + Trim(Copy(Line, Indx + 1, 8)));
      Name := Trim(Copy(Line, Indx + 9, Length(Line)));

      if StringInSet(StrSplit(Name, '.')[0], IGNORE) then
        Continue;

      if not FDict.ContainsKey(Name) then
      begin
        List := TList<Pointer>.Create;
        FDict.Add(Name, List);
      end
      else
      begin
        List := FDict[Name];
      end;

      Address := Pointer(FHeader[Code] + Base);
      if List.IndexOf(Address) = -1 then
        List.Add(Address);
    end;

    Inc(Start, 2);
    if Pos('Address', Trim(AMapFile[Start])) > -1 then
      Break;

    Inc(Start, 2);
  end;
end;

procedure TMapFile.ParseHeader(AMapFile: TStringList);
var
  Line: string;
  I, Start, Code, Indx: Integer;
  Base: Cardinal;
begin
  Start := 0;
  while Trim(AMapFile[Start]) = EmptyStr do
    Inc(Start);

  Inc(Start);
  for I := 1 to 6 do
  begin
    Line := AMapFile[Start];
    Indx := Pos(':', Line);
    Code := StrToInt('$' + Trim(Copy(Line, 1, Indx - 1)));
    if Code < 7 then
    begin
      Base := StrToInt('$' + Copy(Line, Indx + 1, 8));
      FHeader[Code] := Base;
    end;
    Inc(Start);
  end;

  for I := 0 to Start + 3 do
    AMapFile.Delete(0);
end;

function TMapFile.StringInSet(const AValue: string; const ASet: array of string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(ASet) to High(ASet) do
  begin
    if SameText(AValue, ASet[I]) then
      Exit(True);
  end;
end;

function TMapFile.StrSplit(const AValue: string; const ADelimiter: Char): TArray<string>;
var
  I: Integer;
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Delimiter := ADelimiter;
    L.DelimitedText := AValue;

    SetLength(Result, L.Count);
    for I := 0 to L.Count - 1 do
      Result[I] := L[I];
  finally
    L.Free;
  end;
end;

end.
