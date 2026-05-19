object Form5: TForm5
  Left = 0
  Top = 0
  Caption = 'Form5'
  ClientHeight = 594
  ClientWidth = 834
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    834
    594)
  TextHeight = 15
  object PortEdit: TAdvEdit
    Left = 48
    Top = 112
    Width = 160
    Height = 23
    EmptyTextStyle = []
    FlatLineColor = 11250603
    FocusColor = clWindow
    FocusFontColor = 3881787
    LabelCaption = 'Port'
    LabelPosition = lpLeftCenter
    LabelFont.Charset = DEFAULT_CHARSET
    LabelFont.Color = clWindowText
    LabelFont.Height = -12
    LabelFont.Name = 'Segoe UI'
    LabelFont.Style = []
    Lookup.Font.Charset = DEFAULT_CHARSET
    Lookup.Font.Color = clWindowText
    Lookup.Font.Height = -11
    Lookup.Font.Name = 'Segoe UI'
    Lookup.Font.Style = []
    Lookup.Separator = ';'
    Color = clWindow
    TabOrder = 0
    Text = '8777'
    Visible = True
    Version = '4.0.6.2'
  end
  object S2AliasComboBox1: TS2AliasComboBox
    Left = 8
    Top = 8
    Width = 200
    Height = 23
    LineColor = 15855083
    FixedLineColor = 13745060
    HeaderColor = clWhite
    HeaderHeight = 25
    HeaderFont.Charset = DEFAULT_CHARSET
    HeaderFont.Color = clWindowText
    HeaderFont.Height = -12
    HeaderFont.Name = 'Segoe UI'
    HeaderFont.Style = []
    DropDownHeight = 200
    LabelFont.Charset = DEFAULT_CHARSET
    LabelFont.Color = clWindowText
    LabelFont.Height = -12
    LabelFont.Name = 'Segoe UI'
    LabelFont.Style = []
    Version = '1.5.7.3'
    SelectionColor = 14155773
    ButtonAppearance.Font.Charset = DEFAULT_CHARSET
    ButtonAppearance.Font.Color = clWindowText
    ButtonAppearance.Font.Height = -11
    ButtonAppearance.Font.Name = 'Segoe UI'
    ButtonAppearance.Font.Style = []
    DropDownHeader.Font.Charset = DEFAULT_CHARSET
    DropDownHeader.Font.Color = clWindowText
    DropDownHeader.Font.Height = -11
    DropDownHeader.Font.Name = 'Segoe UI'
    DropDownHeader.Font.Style = []
    DropDownHeader.Visible = True
    DropDownHeader.Buttons = <>
    DropDownFooter.Font.Charset = DEFAULT_CHARSET
    DropDownFooter.Font.Color = clWindowText
    DropDownFooter.Font.Height = -11
    DropDownFooter.Font.Name = 'Segoe UI'
    DropDownFooter.Font.Style = []
    DropDownFooter.Visible = True
    DropDownFooter.Buttons = <>
    TabOrder = 1
    DBUser = 'DBA'
    DBPassword = 'System2000xx'
    DBPassIsHash = False
    ShowUserPrompt = False
    Session = DB
    AutoDBConnect = False
    AllowParamLogin = False
    SelectionColorStyle = 1
    TMSStyle = 8
  end
  object btnConnect: TAdvGlowButton
    Left = 8
    Top = 48
    Width = 200
    Height = 33
    Caption = 'Connect'
    NotesFont.Charset = DEFAULT_CHARSET
    NotesFont.Color = clWindowText
    NotesFont.Height = -11
    NotesFont.Name = 'Tahoma'
    NotesFont.Style = []
    Rounded = False
    TabOrder = 2
    OnClick = btnConnectClick
    Appearance.BorderColor = 11382963
    Appearance.BorderColorHot = 11565130
    Appearance.BorderColorCheckedHot = 11565130
    Appearance.BorderColorDown = 11565130
    Appearance.BorderColorChecked = 13744549
    Appearance.BorderColorDisabled = 13948116
    Appearance.Color = clWhite
    Appearance.ColorTo = clWhite
    Appearance.ColorChecked = 13744549
    Appearance.ColorCheckedTo = 13744549
    Appearance.ColorDisabled = clWhite
    Appearance.ColorDisabledTo = clNone
    Appearance.ColorDown = 11565130
    Appearance.ColorDownTo = 11565130
    Appearance.ColorHot = 16444643
    Appearance.ColorHotTo = 16444643
    Appearance.ColorMirror = clWhite
    Appearance.ColorMirrorTo = clWhite
    Appearance.ColorMirrorHot = 16444643
    Appearance.ColorMirrorHotTo = 16444643
    Appearance.ColorMirrorDown = 11565130
    Appearance.ColorMirrorDownTo = 11565130
    Appearance.ColorMirrorChecked = 13744549
    Appearance.ColorMirrorCheckedTo = 13744549
    Appearance.ColorMirrorDisabled = clWhite
    Appearance.ColorMirrorDisabledTo = clNone
    Appearance.GradientHot = ggVertical
    Appearance.GradientMirrorHot = ggVertical
    Appearance.GradientDown = ggVertical
    Appearance.GradientMirrorDown = ggVertical
    Appearance.GradientChecked = ggVertical
    Appearance.TextColorChecked = 3750459
    Appearance.TextColorDown = 2303013
    Appearance.TextColorHot = 2303013
    Appearance.TextColorDisabled = 13948116
  end
  object LogMemo: TAdvMemo
    Left = 214
    Top = 8
    Width = 612
    Height = 578
    Cursor = crIBeam
    ActiveLineSettings.ShowActiveLine = False
    ActiveLineSettings.ShowActiveLineIndicator = False
    Anchors = [akLeft, akTop, akRight, akBottom]
    AutoCompletion.Font.Charset = DEFAULT_CHARSET
    AutoCompletion.Font.Color = clWindowText
    AutoCompletion.Font.Height = -12
    AutoCompletion.Font.Name = 'Segoe UI'
    AutoCompletion.Font.Style = []
    AutoCompletion.StartToken = '(.'
    AutoCorrect.Active = True
    AutoHintParameterPosition = hpBelowCode
    BkColor = clWindow
    BookmarkGlyph.Data = {
      36050000424D3605000000000000360400002800000010000000100000000100
      0800000000000001000000000000000000000001000000000000000000000000
      80000080000000808000800000008000800080800000C0C0C000C0DCC000F0CA
      A6000020400000206000002080000020A0000020C0000020E000004000000040
      20000040400000406000004080000040A0000040C0000040E000006000000060
      20000060400000606000006080000060A0000060C0000060E000008000000080
      20000080400000806000008080000080A0000080C0000080E00000A0000000A0
      200000A0400000A0600000A0800000A0A00000A0C00000A0E00000C0000000C0
      200000C0400000C0600000C0800000C0A00000C0C00000C0E00000E0000000E0
      200000E0400000E0600000E0800000E0A00000E0C00000E0E000400000004000
      20004000400040006000400080004000A0004000C0004000E000402000004020
      20004020400040206000402080004020A0004020C0004020E000404000004040
      20004040400040406000404080004040A0004040C0004040E000406000004060
      20004060400040606000406080004060A0004060C0004060E000408000004080
      20004080400040806000408080004080A0004080C0004080E00040A0000040A0
      200040A0400040A0600040A0800040A0A00040A0C00040A0E00040C0000040C0
      200040C0400040C0600040C0800040C0A00040C0C00040C0E00040E0000040E0
      200040E0400040E0600040E0800040E0A00040E0C00040E0E000800000008000
      20008000400080006000800080008000A0008000C0008000E000802000008020
      20008020400080206000802080008020A0008020C0008020E000804000008040
      20008040400080406000804080008040A0008040C0008040E000806000008060
      20008060400080606000806080008060A0008060C0008060E000808000008080
      20008080400080806000808080008080A0008080C0008080E00080A0000080A0
      200080A0400080A0600080A0800080A0A00080A0C00080A0E00080C0000080C0
      200080C0400080C0600080C0800080C0A00080C0C00080C0E00080E0000080E0
      200080E0400080E0600080E0800080E0A00080E0C00080E0E000C0000000C000
      2000C0004000C0006000C0008000C000A000C000C000C000E000C0200000C020
      2000C0204000C0206000C0208000C020A000C020C000C020E000C0400000C040
      2000C0404000C0406000C0408000C040A000C040C000C040E000C0600000C060
      2000C0604000C0606000C0608000C060A000C060C000C060E000C0800000C080
      2000C0804000C0806000C0808000C080A000C080C000C080E000C0A00000C0A0
      2000C0A04000C0A06000C0A08000C0A0A000C0A0C000C0A0E000C0C00000C0C0
      2000C0C04000C0C06000C0C08000C0C0A000F0FBFF00A4A0A000808080000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00FDFD25252525
      2525252525252525FDFDFD2E25FFFFFFFFFFFFFFFFFFFF25FDFDFD2525252525
      2525252525252525FDFD9A9AB7B7B7B7B7B7B7B7B7B72525FDFDFD25B7B7B7B7
      B7B7B7B7B7B72525FDFD9A9AB7B7B7B7B7B7B7B7B7B72525FDFDFD25BFB7BFBF
      B7B7B7B7B7B72525FDFD9A9ABFBFBFB7BFBFB7B7B7B72525FDFDFD25BFBFBFBF
      BFB7BFBFB7B72525FDFD9A9ABFBFBFB7BFBFBFB7BFB72525FDFDFD25BFBFBFBF
      BFBFBFBFBFB72525FDFD9A9ABFBFBFBFBFB7BFBFB7B72525FDFDFD25BFBFBFBF
      BFBFBFBFBFB72525FDFD9A9ABFBFBFBFBFBFBFBFBFB725FDFDFDFD2525252525
      25252525252525FDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFD}
    BorderStyle = bsSingle
    ClipboardFormats = [cfText]
    CodeFolding.Enabled = False
    CodeFolding.LineColor = clGray
    Ctl3D = False
    DelErase = True
    EnhancedHomeKey = False
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -13
    Gutter.Font.Name = 'Courier New'
    Gutter.Font.Style = []
    Gutter.GutterColorTo = clBtnFace
    Gutter.LineNumberTextColor = clWindowText
    Gutter.Visible = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -13
    Font.Name = 'COURIER NEW'
    Font.Style = []
    HiddenCaret = False
    Lines.Strings = (
      '')
    MarkerList.UseDefaultMarkerImageIndex = False
    MarkerList.DefaultMarkerImageIndex = -1
    MarkerList.ImageTransparentColor = 33554432
    OleDropTarget = []
    PrintOptions.MarginLeft = 0
    PrintOptions.MarginRight = 0
    PrintOptions.MarginTop = 0
    PrintOptions.MarginBottom = 0
    PrintOptions.PageNr = False
    PrintOptions.PrintLineNumbers = False
    RightMarginColor = 14869218
    ScrollHint = False
    SelColor = clHighlightText
    SelBkColor = clHighlight
    ShowRightMargin = True
    SmartTabs = False
    TabOrder = 3
    TabStop = True
    TrimTrailingSpaces = False
    UILanguage.ScrollHint = 'Row'
    UILanguage.Undo = 'Undo'
    UILanguage.Redo = 'Redo'
    UILanguage.Copy = 'Copy'
    UILanguage.Cut = 'Cut'
    UILanguage.Paste = 'Paste'
    UILanguage.Delete = 'Delete'
    UILanguage.SelectAll = 'Select All'
    UrlStyle.TextColor = clBlue
    UrlStyle.BkColor = clWhite
    UrlStyle.Style = [fsUnderline]
    UseStyler = True
    Version = '3.9.2.0'
    WordWrap = wwNone
  end
  object StartButton: TAdvGlowButton
    Left = 8
    Top = 152
    Width = 200
    Height = 33
    Caption = 'Start'
    NotesFont.Charset = DEFAULT_CHARSET
    NotesFont.Color = clWindowText
    NotesFont.Height = -11
    NotesFont.Name = 'Tahoma'
    NotesFont.Style = []
    Rounded = False
    TabOrder = 4
    OnClick = StartButtonClick
    Appearance.BorderColor = 11382963
    Appearance.BorderColorHot = 11565130
    Appearance.BorderColorCheckedHot = 11565130
    Appearance.BorderColorDown = 11565130
    Appearance.BorderColorChecked = 13744549
    Appearance.BorderColorDisabled = 13948116
    Appearance.Color = clWhite
    Appearance.ColorTo = clWhite
    Appearance.ColorChecked = 13744549
    Appearance.ColorCheckedTo = 13744549
    Appearance.ColorDisabled = clWhite
    Appearance.ColorDisabledTo = clNone
    Appearance.ColorDown = 11565130
    Appearance.ColorDownTo = 11565130
    Appearance.ColorHot = 16444643
    Appearance.ColorHotTo = 16444643
    Appearance.ColorMirror = clWhite
    Appearance.ColorMirrorTo = clWhite
    Appearance.ColorMirrorHot = 16444643
    Appearance.ColorMirrorHotTo = 16444643
    Appearance.ColorMirrorDown = 11565130
    Appearance.ColorMirrorDownTo = 11565130
    Appearance.ColorMirrorChecked = 13744549
    Appearance.ColorMirrorCheckedTo = 13744549
    Appearance.ColorMirrorDisabled = clWhite
    Appearance.ColorMirrorDisabledTo = clNone
    Appearance.GradientHot = ggVertical
    Appearance.GradientMirrorHot = ggVertical
    Appearance.GradientDown = ggVertical
    Appearance.GradientMirrorDown = ggVertical
    Appearance.GradientChecked = ggVertical
    Appearance.TextColorChecked = 3750459
    Appearance.TextColorDown = 2303013
    Appearance.TextColorHot = 2303013
    Appearance.TextColorDisabled = 13948116
    Enabled = False
  end
  object DB: TS2asaSession
    ResourceOptions.AssignedValues = [rvAutoConnect, rvAutoReconnect]
    ResourceOptions.AutoConnect = False
    ResourceOptions.AutoReconnect = True
    LoginPrompt = False
    AfterDisconnect = DBAfterDisconnect
    DebugID = 0
    AfterS2Connect = DBAfterS2Connect
    Left = 224
    Top = 8
  end
end
