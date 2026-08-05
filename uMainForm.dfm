object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Управление устройствами и сенсорами'
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
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 600
    Align = alClient
    TabOrder = 0
    object pnlDevices: TPanel
      Left = 1
      Top = 1
      Width = 398
      Height = 598
      Align = alLeft
      TabOrder = 0
      object grdDevices: TStringGrid
        Left = 1
        Top = 1
        Width = 396
        Height = 596
        Align = alClient
        ColCount = 5
        DefaultColWidth = 80
        DefaultRowHeight = 24
        FixedCols = 0
        RowCount = 2
        FixedRows = 1
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
        TabOrder = 0
        OnClick = grdDevicesClick
        OnDblClick = grdDevicesDblClick
      end
    end
  end
  object splMain: TSplitter
    Left = 399
    Top = 1
    Height = 598
  end
  object pnlSensors: TPanel
    Left = 400
    Top = 1
    Width = 399
    Height = 598
    Align = alClient
    TabOrder = 2
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
        Width = 50
      end
    end
    SimplePanel = False
  end
  object mnuMain: TMainMenu
    Left = 640
    Top = 8
    object mnuFile: TMenuItem
      Caption = 'Файл'
      object mnuExit: TMenuItem
        Caption = 'Выход'
        OnClick = mnuExitClick
      end
    end
    object mnuDevices: TMenuItem
      Caption = 'Устройства'
      object mnuConnect: TMenuItem
        Caption = 'Подключить'
        OnClick = mnuConnectClick
      end
      object mnuDisconnect: TMenuItem
        Caption = 'Отключить'
        OnClick = mnuDisconnectClick
      end
    end
    object mnuHelp: TMenuItem
      Caption = 'Справка'
      object mnuAbout: TMenuItem
        Caption = 'О программе'
        OnClick = mnuAboutClick
      end
    end
  end
  object tlbMain: TToolBar
    Left = 0
    Top = 0
    Width = 800
    Height = 31
    AutoSize = True
    ButtonHeight = 27
    ButtonWidth = 67
    Caption = 'tlbMain'
    Images = ilMain
    TabOrder = 4
    object btnConnect: TToolButton
      Left = 0
      Top = 0
      Caption = 'Подключить'
      ImageIndex = 0
      OnClick = btnConnectClick
    end
    object btnDisconnect: TToolButton
      Left = 67
      Top = 0
      Caption = 'Отключить'
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
      Caption = 'Обновить'
      ImageIndex = 2
      OnClick = btnRefreshClick
    end
  end
  object ilMain: TImageList
    Left = 680
    Top = 8
  end
  object tmrPoll: TTimer
    Interval = 1000
    OnTimer = tmrPollTimer
    Left = 720
    Top = 8
  end
end
