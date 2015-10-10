object Form1: TForm1
  Left = 565
  Top = 292
  Width = 927
  Height = 384
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object dbgrd1: TDBGrid
    Left = 0
    Top = 49
    Width = 911
    Height = 296
    Align = alClient
    DataSource = ds1
    ImeName = #23567#29436#27627
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnDblClick = dbgrd1DblClick
  end
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 911
    Height = 49
    Align = alTop
    Caption = 'pnl1'
    TabOrder = 1
    object edt1: TEdit
      Left = 248
      Top = 16
      Width = 233
      Height = 21
      ImeName = #23567#29436#27627
      TabOrder = 0
      Text = 'Software\MyCompanyName\MyApplication\'
    end
    object btn2: TButton
      Left = 520
      Top = 16
      Width = 49
      Height = 25
      Caption = 'load'
      TabOrder = 1
      OnClick = btn2Click
    end
    object cbb1: TComboBox
      Left = 40
      Top = 16
      Width = 185
      Height = 21
      ImeName = #23567#29436#27627
      ItemHeight = 13
      ItemIndex = 1
      TabOrder = 2
      Text = ' HKEY_CURRENT_USER'
      Items.Strings = (
        ' HKEY_CLASSES_ROOT'
        ' HKEY_CURRENT_USER'
        ' HKEY_LOCAL_MACHINE'
        ' HKEY_USERS           '
        ' HKEY_PERFORMANCE_DATA '
        ' HKEY_CURRENT_CONFIG  '
        ' HKEY_DYN_DATA         ')
    end
    object btnUp: TButton
      Left = 576
      Top = 16
      Width = 49
      Height = 25
      Caption = 'up'
      TabOrder = 3
      OnClick = btnUpClick
    end
    object btnDel: TButton
      Left = 640
      Top = 16
      Width = 49
      Height = 25
      Caption = 'Delete'
      TabOrder = 4
      OnClick = btnDelClick
    end
    object btnEdit: TButton
      Left = 696
      Top = 16
      Width = 49
      Height = 25
      Caption = 'Edit'
      TabOrder = 5
      OnClick = btnEditClick
    end
    object btnRoot: TButton
      Left = 752
      Top = 16
      Width = 49
      Height = 25
      Caption = '\'
      TabOrder = 6
      OnClick = btnRootClick
    end
    object btnAdd: TButton
      Left = 808
      Top = 16
      Width = 49
      Height = 25
      Caption = 'Add Key'
      TabOrder = 7
      OnClick = btnAddClick
    end
    object btnTest: TButton
      Left = 864
      Top = 16
      Width = 33
      Height = 25
      Caption = 'T'
      TabOrder = 8
    end
  end
  object ds1: TDataSource
    DataSet = ds2
    Left = 112
    Top = 64
  end
  object ds2: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 168
    Top = 64
  end
end
