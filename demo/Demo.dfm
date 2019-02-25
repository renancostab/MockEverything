object Form1: TForm1
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Demo'
  ClientHeight = 309
  ClientWidth = 645
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Log: TMemo
    Left = 202
    Top = 0
    Width = 443
    Height = 309
    Align = alRight
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Mock Sum'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 102
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Remove Sum'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 8
    Top = 52
    Width = 169
    Height = 25
    Caption = 'Mock Everything'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 8
    Top = 94
    Width = 169
    Height = 25
    Caption = 'Restore Everything'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 12
    Top = 224
    Width = 165
    Height = 63
    Caption = 'Run'
    TabOrder = 5
    OnClick = Button5Click
  end
end
