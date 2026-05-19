unit S2CallsHttpServer;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  IdHTTPServer,
  IdContext,
  IdCustomHTTPServer,
  FireDAC.Comp.Client,
  IdException,
  S2AsaSession;

type
  TS2CallsHttpServer = class
  private
    FServer: TIdHTTPServer;
    FConnection: TS2AsaSession;

    procedure AddCorsHeaders(
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo
    );

    function HandlePreflight(
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo
    ): Boolean;

    procedure HTTPServerCommandAll(
      AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo
    );

    procedure HandleRecentCalls(
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo
    );

    procedure WriteJson(
      AResponseInfo: TIdHTTPResponseInfo;
      AJson: TJSONValue;
      AStatusCode: Integer = 200
    );

    procedure WriteJsonText(
      AResponseInfo: TIdHTTPResponseInfo;
      const AText: string;
      AStatusCode: Integer = 200
    );

  public
    constructor Create(AConnection: TS2AsaSession; APort: Integer = 8080);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

    property Server: TIdHTTPServer read FServer;
  end;

implementation

uses
  S2CallsRepository;

constructor TS2CallsHttpServer.Create(AConnection: TS2AsaSession; APort: Integer);
begin
  inherited Create;

  FConnection := AConnection;

  FServer := TIdHTTPServer.Create(nil);
  FServer.DefaultPort := APort;
  FServer.TerminateWaitTime := 5000;
  FServer.OnCommandGet := HTTPServerCommandAll;
  FServer.OnCommandOther := HTTPServerCommandAll;
end;

procedure TS2CallsHttpServer.Start;
begin
  FServer.Active := True;
end;

destructor TS2CallsHttpServer.Destroy;
begin
  Stop;
  FreeAndNil(FServer);
  inherited;
end;

procedure TS2CallsHttpServer.Stop;
begin
  if not Assigned(FServer) then
    Exit;
  if FServer.Active then
    FServer.Active := False;

  FServer.OnCommandGet := nil;
  FServer.OnCommandOther := nil;


end;

procedure TS2CallsHttpServer.AddCorsHeaders(
  ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
begin
  AResponseInfo.CustomHeaders.Values['Access-Control-Allow-Origin'] := '*';
  AResponseInfo.CustomHeaders.Values['Access-Control-Allow-Methods'] := 'GET, POST, PUT, DELETE, OPTIONS';
  AResponseInfo.CustomHeaders.Values['Access-Control-Allow-Headers'] := 'Content-Type, Accept';
end;

function TS2CallsHttpServer.HandlePreflight(
  ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo): Boolean;
begin
  Result := SameText(ARequestInfo.Command, 'OPTIONS');

  if Result then
  begin
    AddCorsHeaders(ARequestInfo, AResponseInfo);
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'text/plain; charset=utf-8';
    AResponseInfo.ContentText := '';
  end;
end;

procedure TS2CallsHttpServer.HTTPServerCommandAll(
  AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var
  Path: string;
begin
  try
    AddCorsHeaders(ARequestInfo, AResponseInfo);

    if HandlePreflight(ARequestInfo, AResponseInfo) then
      Exit;

    Path := ARequestInfo.Document;

    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := '{"error":"NOT_FOUND"}';

    if SameText(ARequestInfo.Command, 'GET') then
    begin
      if SameText(Path, '/api/v1/calls/recent') then
      begin
        HandleRecentCalls(ARequestInfo, AResponseInfo);
        Exit;
      end;
    end;

  except
    on E: Exception do
      WriteJsonText(AResponseInfo,
        '{"error":"INTERNAL_SERVER_ERROR","message":"' + StringReplace(E.Message, '"', '\"', [rfReplaceAll]) + '"}',
        500
      );
  end;
end;

procedure TS2CallsHttpServer.HandleRecentCalls(
  ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var
  Repo: TS2CallsRepository;
  J: TJSONArray;
  Limit: Integer;
begin
  Limit := StrToIntDef(ARequestInfo.Params.Values['limit'], 10);

  Repo := TS2CallsRepository.Create(FConnection);
  try
    J := Repo.GetRecentCalls(Limit);
    try
      WriteJson(AResponseInfo, J);
    finally
      J.Free;
    end;
  finally
    Repo.Free;
  end;
end;

procedure TS2CallsHttpServer.WriteJson(
  AResponseInfo: TIdHTTPResponseInfo;
  AJson: TJSONValue;
  AStatusCode: Integer);
begin
  WriteJsonText(AResponseInfo, AJson.ToJSON, AStatusCode);
end;

procedure TS2CallsHttpServer.WriteJsonText(
  AResponseInfo: TIdHTTPResponseInfo;
  const AText: string;
  AStatusCode: Integer);
begin
  AResponseInfo.ResponseNo := AStatusCode;
  AResponseInfo.ContentType := 'application/json; charset=utf-8';
  AResponseInfo.ContentText := AText;
end;

end.

