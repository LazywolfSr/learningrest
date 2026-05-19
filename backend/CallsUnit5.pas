unit CallsUnit5;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, AdvEdit,
   S2CallsRepository, S2CallsHttpServer, AdvMemo, AdvGlowButton, Vcl.Mask,
  AdvDropDown, VCL.S2AdvMultiColumnDropDown, VCL.DBCombo,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait, Vcl.ExtCtrls,
  IdStackWindows,
  Data.DB, FireDAC.Comp.Client, VCL.S2asaSession;

type
  TForm5 = class(TForm)
    PortEdit: TAdvEdit;
    S2AliasComboBox1: TS2AliasComboBox;
    btnConnect: TAdvGlowButton;
    LogMemo: TAdvMemo;
    StartButton: TAdvGlowButton;
    DB: TS2asaSession;
    procedure StartButtonClick(Sender: TObject);
    procedure DBAfterDisconnect(Sender: TObject);
    procedure DBAfterS2Connect(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    Server : TS2CallsHttpServer;
    procedure StartAll;
    procedure ListLocalIPs;
  public
  end;

var
  Form5: TForm5;

implementation
uses
  IdGlobal, IdStack;


{$R *.dfm}

procedure TForm5.btnConnectClick(Sender: TObject);
begin
  if DB.Connected then begin
    DB.Connected := false;
  end else begin
    StartAll;
  end;
end;


procedure TForm5.ListLocalIPs;
var
  L: TIdStackLocalAddressList;
  I: Integer;
begin
  L := TIdStackLocalAddressList.Create;
  try
    GStack.GetLocalAddressList(L);

    for I := 0 to L.Count - 1 do
    begin
      if L[I].IPVersion = Id_IPv4 then
        LogMemo.Lines.Add('IPv4: ' + L[I].IPAddress);
    end;

  finally
    L.Free;
  end;
end;

procedure TForm5.StartAll;
begin
  if S2AliasComboBox1.Connect then begin
    Server.Start;
    ListLocalIPs;
  end;
end;

procedure TForm5.DBAfterDisconnect(Sender: TObject);
begin
  StartButton.Enabled := false;
  btnConnect.Caption := 'verbinden';
end;

procedure TForm5.DBAfterS2Connect(Sender: TObject);
begin
  StartButton.Enabled := true;
  btnConnect.Caption := 'trennen';
  LogMemo.Lines.Add(DB.Params.Text);
end;

procedure TForm5.FormCreate(Sender: TObject);
begin
  Server := TS2CallsHttpServer.Create(DB, PortEdit.Text.ToInteger);
end;

procedure TForm5.FormDestroy(Sender: TObject);
begin
  FreeAndNIL(Server);
end;

procedure TForm5.StartButtonClick(Sender: TObject);
begin
  StartAll;
end;

end.
