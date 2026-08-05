object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = #1059#1087#1088#1072#1074#1083#1077#1085#1080#1077' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1072#1084#1080' '#1080' '#1089#1077#1085#1089#1086#1088#1072#1084#1080
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object splMain: TSplitter
    Left = 0
    Top = 27
    Height = 552
    ExplicitLeft = 399
    ExplicitTop = 1
    ExplicitHeight = 598
  end
  object pnlMain: TPanel
    Left = 3
    Top = 27
    Width = 797
    Height = 552
    Align = alClient
    TabOrder = 0
    object pnlDevices: TPanel
      Left = 1
      Top = 1
      Width = 398
      Height = 550
      Align = alLeft
      TabOrder = 0
      object grdDevices: TStringGrid
        Left = 1
        Top = 1
        Width = 396
        Height = 548
        Align = alClient
        DefaultColWidth = 80
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
        TabOrder = 0
        OnClick = grdDevicesClick
        OnDblClick = grdDevicesDblClick
      end
    end
  end
  object pnlSensors: TPanel
    Left = 3
    Top = 27
    Width = 797
    Height = 552
    Align = alClient
    TabOrder = 2
    ExplicitLeft = 8
    ExplicitTop = 21
  end
  object stbMain: TStatusBar
    Left = 0
    Top = 579
    Width = 800
    Height = 21
    Panels = <
      item
        Width = 50
      end
      item
        Width = 100
      end>
  end
  object tlbMain: TToolBar
    Left = 0
    Top = 0
    Width = 800
    Height = 27
    AutoSize = True
    ButtonHeight = 27
    ButtonWidth = 67
    Caption = 'tlbMain'
    Images = ilMain
    TabOrder = 3
    object btnConnect: TToolButton
      Left = 0
      Top = 0
      Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100
      ImageIndex = 0
      OnClick = btnConnectClick
    end
    object btnDisconnect: TToolButton
      Left = 67
      Top = 0
      Caption = #1054#1090#1082#1083#1102#1095#1080#1090#1100
      ImageIndex = 1
      OnClick = btnDisconnectClick
    end
    object sep1: TToolButton
      Left = 134
      Top = 0
      Width = 8
      Caption = 'sep1'
      ImageIndex = 1
      Style = tbsSeparator
    end
    object btnRefresh: TToolButton
      Left = 142
      Top = 0
      Caption = #1054#1073#1085#1086#1074#1080#1090#1100
      ImageIndex = 2
      OnClick = btnRefreshClick
    end
  end
  object mnuMain: TMainMenu
    Left = 640
    Top = 8
    object mnuFile: TMenuItem
      Caption = #1060#1072#1081#1083
      object mnuExit: TMenuItem
        Caption = #1042#1099#1093#1086#1076
        OnClick = mnuExitClick
      end
    end
    object mnuDevices: TMenuItem
      Caption = #1059#1089#1090#1088#1086#1081#1089#1090#1074#1072
      object mnuConnect: TMenuItem
        Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100
        OnClick = mnuConnectClick
      end
      object mnuDisconnect: TMenuItem
        Caption = #1054#1090#1082#1083#1102#1095#1080#1090#1100
        OnClick = mnuDisconnectClick
      end
    end
    object mnuHelp: TMenuItem
      Caption = #1057#1087#1088#1072#1074#1082#1072
      object mnuAbout: TMenuItem
        Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077
        OnClick = mnuAboutClick
      end
    end
  end
  object ilMain: TImageList
    Left = 680
    Top = 8
  end
  object tmrPoll: TTimer
    OnTimer = tmrPollTimer
    Left = 720
    Top = 8
  end
end
