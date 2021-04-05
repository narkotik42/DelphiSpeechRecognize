object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'Speech Recognize'
  ClientHeight = 405
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 364
    Width = 500
    Height = 41
    Align = alBottom
    TabOrder = 0
    object BtnRun: TButton
      Left = 200
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Run'
      TabOrder = 0
      OnClick = BtnRunClick
    end
  end
  object MemResult: TMemo
    Left = 0
    Top = 0
    Width = 500
    Height = 347
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
    ExplicitHeight = 364
  end
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 347
    Width = 500
    Height = 17
    Align = alBottom
    TabOrder = 2
    ExplicitLeft = 104
    ExplicitTop = 256
    ExplicitWidth = 150
  end
end
