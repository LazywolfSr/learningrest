program CallsProject1;

uses
  Vcl.Forms,
  CallsUnit5 in 'CallsUnit5.pas' {Form5},
  S2CallsRepository in 'S2CallsRepository.pas',
  S2CallsHttpServer in 'S2CallsHttpServer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm5, Form5);
  Application.Run;
end.
