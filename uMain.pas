unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, uSbSpeechRecognize, Vcl.ComCtrls;

type
  TFrmMain = class(TForm)
    Panel1: TPanel;
    BtnRun: TButton;
    MemResult: TMemo;
    ProgressBar1: TProgressBar;
    procedure BtnRunClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure CstResultEvent(Sender: TObject; SpeechResult:TSpeechResult);
    procedure CstProcessEvent(Sender: TObject; Position:Integer);
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;
  SbSpeechRecognize : TSbSpeechRecognize;
implementation
  uses Soap.EncdDecd, System.NetEncoding;
{$R *.dfm}

function EncodeFile(const FileName: string): String;
var
  MemStream: TMemoryStream;
begin
  MemStream := TMemoryStream.Create;
  try
    MemStream.LoadFromFile(Filename);
    MemStream.Position := 0;
    Result :=  TNetEncoding.Base64.EncodeBytesToString(MemStream.Memory, MemStream.Size);
  finally
    MemStream.Free;
  end;
end;

procedure TFrmMain.BtnRunClick(Sender: TObject);
var
  xSpeechParam : TSpeechParam;
begin
  {
    Çok büyük dosyalarda cloud storage upload etmek gerekli
    Cloud storage entegrasyonu token + upload file
    Cloud storage entegrasyonu sonra yapýlacak
    Geçici olarak TMS Cloud Pack kullanýlabilir
  }

  BtnRun.Enabled := False;
  MemResult.Lines.Clear;

  xSpeechParam.SoundSource := EncodeFile('C:\Users\narkotik\Desktop\Kayit.flac');
  SbSpeechRecognize.ApiKey := '';
  SbSpeechRecognize.OnResult := CstResultEvent;
  SbSpeechRecognize.OnProcess := CstProcessEvent;

  TThread.CreateAnonymousThread(
    procedure()
    begin
      SbSpeechRecognize.GetSpeechRecognize(xSpeechParam);
    end).Start;
end;

procedure TFrmMain.CstProcessEvent(Sender: TObject; Position: Integer);
begin
  ProgressBar1.Position := Position;
end;

procedure TFrmMain.CstResultEvent(Sender: TObject; SpeechResult: TSpeechResult);
var
  Ind : Integer;
begin
  BtnRun.Enabled := True;
  if SpeechResult.Error then
    ShowMessage(SpeechResult.ErrorStr)
  else
  begin
    for Ind := Low(SpeechResult.TextArr) to High(SpeechResult.TextArr) do
      MemResult.Lines.Add(Trim(SpeechResult.TextArr[Ind]));
  end;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  SbSpeechRecognize := TSbSpeechRecognize.Create(nil);
end;

end.
