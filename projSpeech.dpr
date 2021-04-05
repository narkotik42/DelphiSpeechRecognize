program projSpeech;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {FrmMain},
  uSbSpeechRecognize in 'Lib\uSbSpeechRecognize.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
