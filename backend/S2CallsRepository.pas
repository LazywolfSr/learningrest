unit S2CallsRepository;

interface

uses
  System.SysUtils,
  System.JSON,
  FireDAC.Comp.Client,
  S2Types,
  S2AsaSession;

type
  TS2CallsRepository = class
  private
    FConnection: TS2AsaSession;
  public
    constructor Create(AConnection: TS2AsaSession);

    function GetRecentCalls(ALimit: Integer): TJSONArray;
  end;

implementation

constructor TS2CallsRepository.Create(AConnection: TS2AsaSession);
begin
  inherited Create;
  FConnection := AConnection;
end;

function TS2CallsRepository.GetRecentCalls(ALimit: Integer): TJSONArray;
var
  Q: TFDQuery;
  O: TJSONObject;
  s : string;
begin
  Result := TJSONArray.Create;

  if ALimit <= 0 then
    ALimit := 10;

  if ALimit > 500 then
    ALimit := 500;

  if FConnection.DatabaseMode = dmSQLAnywhere then begin
    s :=
      'select top '+ALimit.ToString+' calid as id, createdat as ts, caltelefon as remoteid, calsuch as display ' +
      'from cal ' +
      'where calstatus = 1 ' +
      'order by createdat desc ';

  end else begin
    s :=
      'select id, ts, remote as remoteid, display ' +
      'from calls ' +
      'order by id desc ' +
      'limit '+ALimit.ToString;

  end;
  Q := FConnection.CreateQuery(true, s, []);
  try

    Q.Open;
    while not Q.Eof do
    begin
      O := TJSONObject.Create;

      O.AddPair('id', TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      O.AddPair('ts', Q.FieldByName('ts').AsString);
      O.AddPair('remote', Q.FieldByName('remoteid').AsString);
      O.AddPair('display', Q.FieldByName('display').AsString);

      Result.AddElement(O);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

end.

