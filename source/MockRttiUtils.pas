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
Original Code: MockRttiUtils.pas

***************************************************************************************************)

unit MockRttiUtils;

interface

uses
  SysUtils, Classes, Rtti;

  procedure SetFieldValue(const AObject: TObject; const AField: string; const AValue: TValue);
  procedure SetPropertyValue(const AObject: TObject; const AProperty: string; const AValue: TValue);

  function GetFieldValue(const AObject: TObject; const AField: string): TValue;
  function GetPropertyValue(const AObject: TObject; const AProperty: string): TValue;

implementation

procedure SetFieldValue(const AObject: TObject; const AField: string; const AValue: TValue);
var
  Context: TRttiContext;
  Field: TRttiField;
begin
  if not Assigned(AObject) then
    raise Exception.Create('Invalid instance of object');

  Context := TRttiContext.Create;
  try
    Field := Context.GetType(AObject.ClassInfo).GetField(AField);
    if not Assigned(Field) then
      raise Exception.CreateFmt('Field [%s.%s] not found', [AObject.ClassName, AField]);

    Field.SetValue(AObject, AValue);
  finally
    Context.Free;
  end;
end;

procedure SetPropertyValue(const AObject: TObject; const AProperty: string; const AValue: TValue);
var
  Context: TRttiContext;
  Prop: TRttiProperty;
begin
  if not Assigned(AObject) then
    raise Exception.Create('Invalid instance of object');

  Context := TRttiContext.Create;
  try
    Prop := Context.GetType(AObject.ClassInfo).GetProperty(AProperty);
    if not Assigned(Prop) then
      raise Exception.CreateFmt('Property [%s.%s] not found', [AObject.ClassName, AProperty]);

    Prop.SetValue(AObject, AValue);
  finally
    Context.Free;
  end;

end;

function GetFieldValue(const AObject: TObject; const AField: string): TValue;
var
  Context: TRttiContext;
  Field: TRttiField;
begin
  if not Assigned(AObject) then
    raise Exception.Create('Invalid instance of object');

  Context := TRttiContext.Create;
  try
    Field := Context.GetType(AObject.ClassInfo).GetField(AField);
    if not Assigned(Field) then
      raise Exception.CreateFmt('Field [%s.%s] not found', [AObject.ClassName, AField]);

    Result := Field.GetValue(AObject);
  finally
    Context.Free;
  end;
end;

function GetPropertyValue(const AObject: TObject; const AProperty: string): TValue;
var
  Context: TRttiContext;
  Prop: TRttiProperty;
begin
  if not Assigned(AObject) then
    raise Exception.Create('Invalid instance of object');

  Context := TRttiContext.Create;
  try
    Prop := Context.GetType(AObject.ClassInfo).GetProperty(AProperty);
    if not Assigned(Prop) then
      raise Exception.CreateFmt('Property [%s.%s] not found', [AObject.ClassName, AProperty]);

    Result := Prop.GetValue(AObject);
  finally
    Context.Free;
  end;
end;

end.
