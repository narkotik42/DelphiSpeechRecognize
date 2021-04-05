{-----------------------------------------------------------------------------
 Unit Name: uSbSpeechRecognize
 Author:    Salih BAÐCI
 Date:      04-Nis-2021
 Purpose:
 History:
-----------------------------------------------------------------------------}

unit uSbSpeechRecognize;

interface

  uses System.SysUtils, System.Classes, System.Generics.Collections, System.JSON, System.Types,
    System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent;

  type TSpeechRecognizeUrl=(UrlSmallSound,UrlLongSound,UrlLongControl);
  type TSpeechSoundType=(SndBase64,SndUrl);

  type
  TSpeechParam = record
    LongSoundPost : Boolean;
    SoundType : TSpeechSoundType;
    Encoding : String;
    RateHertz : Integer;
    Language : String;
    AudioChannelCount : Integer;
    SoundSource : String;
    class operator Initialize(out Dest:TSpeechParam);
  end;

  type
  TSpeechResult = record
    Error : Boolean;
    ErrorStr : String;
    TextArr : TStringDynArray;
    class operator Initialize(out Dest:TSpeechResult);
  end;
  type TSpeechResultEvent = procedure(Sender: TObject; SpeechResult:TSpeechResult) of object;
  type TSpeechProcessEvent = procedure(Sender: TObject; Position:Integer) of object; // 0..100

  type
  TSbSpeechRecognize = class(TComponent)
  private
    FApiKey: String;
    FOnResult: TSpeechResultEvent;
    FSoundId: String;
    FOnProcess: TSpeechProcessEvent;
    function GetApiUrl(const AUrlType:TSpeechRecognizeUrl):String;
    procedure NetCompSettingsSet(AReq:TNetHTTPRequest;ACli:TNetHTTPClient);
    function LongSoundControl(var AResultError:TSpeechResult):Boolean;
    procedure SetProcess(const APosition:Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure GetSpeechRecognize(const ASpeechParam:TSpeechParam);
  published
    property ApiKey:String read FApiKey write FApiKey;
    property OnResult: TSpeechResultEvent read FOnResult write FOnResult;
    property OnProcess: TSpeechProcessEvent read FOnProcess write FOnProcess;
  end;

implementation
{ TSbSpeechRecognize }

constructor TSbSpeechRecognize.Create(AOwner: TComponent);
begin
  inherited;
  //
end;

destructor TSbSpeechRecognize.Destroy;
begin
  //
  inherited;
end;

function TSbSpeechRecognize.GetApiUrl(const AUrlType: TSpeechRecognizeUrl): String;
begin
  case AUrlType of
    UrlSmallSound: Result := Format('https://speech.googleapis.com/v1/speech:recognize?key=%s',[FApiKey]);
    UrlLongSound: Result := Format('https://speech.googleapis.com/v1/speech:longrunningrecognize?key=%s',[FApiKey]);
    UrlLongControl: Result := Format('https://speech.googleapis.com/v1/operations/%s?key=%s',[FSoundId,FApiKey]);
  end;
end;

procedure TSbSpeechRecognize.GetSpeechRecognize(const ASpeechParam:TSpeechParam);
var
  Ind : Integer;
  xObjMain,xObjConfig,xObjAudio : TJSONObject;
  xObjGetMain : TJSONObject;
  xArrResults : TJSONArray;
  xSendJsonStr : String;
  xGetJsonStr : String;
  xNetHttp : TNetHTTPRequest;
  xNetClient : TNetHTTPClient;
  xRepStringStream : TStringStream;
  xReqStringStream : TStringStream;
  xNetHeader : TNetHeaders;
  xResult : TSpeechResult;
  xLongControl : Boolean;
  procedure SetErrorResult(const AErrorMessage:String);
  begin
    xResult.Error := Trim(AErrorMessage) <> '';
    xResult.ErrorStr := Trim(AErrorMessage);
    xResult.TextArr := [];
  end;
begin
  SetProcess(0);
  {$REGION 'Json Create'}
    xObjMain := TJSONOBject.Create;
    try
      xObjConfig := TJSONOBject.Create;
      xObjAudio := TJSONOBject.Create;

      xObjConfig.AddPair('encoding',ASpeechParam.Encoding);
      xObjConfig.AddPair('sampleRateHertz',TJSONNumber.Create(ASpeechParam.RateHertz));
      xObjConfig.AddPair('languageCode',ASpeechParam.Language);
      if ASpeechParam.AudioChannelCount > 0 then
        xObjConfig.AddPair('audioChannelCount',TJSONNumber.Create(ASpeechParam.AudioChannelCount));

      case ASpeechParam.SoundType of
        SndBase64 : xObjAudio.AddPair('content',ASpeechParam.SoundSource);
        SndUrl : xObjAudio.AddPair('uri',ASpeechParam.SoundSource);
      end;

      xObjMain.AddPair('config',xObjConfig);
      xObjMain.AddPair('audio',xObjAudio);
      xSendJsonStr := xObjMain.ToJSON;
    finally
      FreeAndNil(xObjMain);
    end;
  {$ENDREGION}
  try
    xSendJsonStr := StringReplace(xSendJsonStr,'\r\n','',[rfReplaceAll]); // karakter problemi
    xNetHttp := TNetHTTPRequest.Create(nil);
    xNetClient := TNetHTTPClient.Create(nil);
    xRepStringStream := TStringStream.Create('',TEncoding.UTF8);
    xReqStringStream := TStringStream.Create(xSendJsonStr,TEncoding.UTF8);
    try
      NetCompSettingsSet(xNetHttp,xNetClient);
      SetLength(xNetHeader,1);
      xNetHeader[0].Name := 'Content-Type';
      xNetHeader[0].Value := 'application/json';
      if ASpeechParam.LongSoundPost then
      begin
        xGetJsonStr := xNetHttp.Post(GetApiUrl(UrlLongSound),xReqStringStream,xRepStringStream,xNetHeader).ContentAsString(TEncoding.UTF8);
        xObjGetMain := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(xGetJsonStr),0) as TJSONObject;
        if xObjGetMain.FindValue('error') <> nil then
          SetErrorResult(xObjGetMain.GetValue<TJSONObject>('error').GetValue<String>('message'))
        else
        begin
          FSoundId := xObjGetMain.GetValue<String>('name');
          xLongControl := False;
          while not xLongControl do
          begin
            xLongControl := LongSoundControl(xResult);
            if not xLongControl then
              Sleep(500);
          end;
        end;
      end
      else
      begin
        xGetJsonStr := xNetHttp.Post(GetApiUrl(UrlSmallSound),xReqStringStream,xRepStringStream,xNetHeader).ContentAsString(TEncoding.UTF8);
        xObjGetMain := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(xGetJsonStr),0) as TJSONObject;
        if xObjGetMain.FindValue('error') <> nil then
          SetErrorResult(xObjGetMain.GetValue<TJSONObject>('error').GetValue<String>('message'))
        else if xObjGetMain.FindValue('results') <> nil then
        begin
          xArrResults := xObjGetMain.GetValue<TJSONArray>('results');
          SetLength(xResult.TextArr,xArrResults.Count);
          for Ind := 0 to Pred(xArrResults.Count) do
            xResult.TextArr[Ind] := xArrResults[Ind].GetValue<TJSONArray>('alternatives')[0].GetValue<String>('transcript');
        end;
      end;
    finally
      if xObjGetMain <> nil then
        FreeAndNil(xObjGetMain);
      FreeAndNil(xReqStringStream);
      FreeAndNil(xRepStringStream);
      FreeAndNil(xNetClient);
      FreeAndNil(xNetHttp);
    end;
  except
    on e:Exception do
    begin
      SetErrorResult(e.Message);
    end;
  end;
  if not xResult.Error then
    SetProcess(100);
  if Assigned(FOnResult) then
    FOnResult(Self,xResult);
end;

function TSbSpeechRecognize.LongSoundControl(var AResultError:TSpeechResult): Boolean;
var
  Ind : Integer;
  xNetHttp : TNetHTTPRequest;
  xNetClient : TNetHTTPClient;
  xRepStringStream : TStringStream;
  xNetHeader : TNetHeaders;
  xGetJsonStr : String;
  xObjGetMain,xObjResponse : TJSONObject;
  xArrResults : TJSONArray;
  procedure SetErrorResult(const AErrorMessage:String);
  begin
    Result := True;
    AResultError.Error := Trim(AErrorMessage) <> '';
    AResultError.ErrorStr := Trim(AErrorMessage);
    AResultError.TextArr := [];
  end;
begin
  Result := False;
  try
    xNetHttp := TNetHTTPRequest.Create(nil);
    xNetClient := TNetHTTPClient.Create(nil);
    xRepStringStream := TStringStream.Create('',TEncoding.UTF8);
    try
      NetCompSettingsSet(xNetHttp,xNetClient);
      SetLength(xNetHeader,1);
      xNetHeader[0].Name := 'Content-Type';
      xNetHeader[0].Value := 'application/json';
      xGetJsonStr := xNetHttp.Get(GetApiUrl(UrlLongControl),xRepStringStream,xNetHeader).ContentAsString(TEncoding.UTF8);
      xObjGetMain := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(xGetJsonStr),0) as TJSONObject;
      if xObjGetMain.FindValue('error') <> nil then
        SetErrorResult(xObjGetMain.GetValue<TJSONObject>('error').GetValue<String>('message'))
      else
      begin
        if (xObjGetMain.FindValue('metadata') <> nil) and (xObjGetMain.GetValue<TJSONObject>('metadata').FindValue('progressPercent') <> nil) then
          SetProcess(xObjGetMain.GetValue<TJSONObject>('metadata').GetValue<Integer>('progressPercent'));
        Result := xObjGetMain.FindValue('done') <> nil;
        if Result then
        begin
          AResultError.Error := False;
          AResultError.ErrorStr := '';
          xObjResponse := xObjGetMain.GetValue<TJSONObject>('response');
          xArrResults := xObjResponse.GetValue<TJSONArray>('results');
          SetLength(AResultError.TextArr,xArrResults.Count);
          for Ind := 0 to Pred(xArrResults.Count) do
            AResultError.TextArr[Ind] := xArrResults[Ind].GetValue<TJSONArray>('alternatives')[0].GetValue<String>('transcript');
        end;
      end;
    finally
      if xObjGetMain <> nil then
        FreeAndNil(xObjGetMain);
      FreeAndNil(xRepStringStream);
      FreeAndNil(xNetClient);
      FreeAndNil(xNetHttp);
    end;
  except
    on e:Exception do
    begin
      SetErrorResult(e.Message);
    end;
  end;
end;

procedure TSbSpeechRecognize.NetCompSettingsSet(AReq: TNetHTTPRequest; ACli: TNetHTTPClient);
begin
  with ACli do
  begin
    HandleRedirects := True;
    ConnectionTimeout := 10000;
    ContentType := 'application/json';
    AcceptCharSet := 'utf-8';
  end;
  with AReq do
  begin
    Client := ACli;
    ConnectionTimeout := 10000;
  end;
end;

procedure TSbSpeechRecognize.SetProcess(const APosition: Integer);
begin
  if Assigned(FOnProcess) then
    FOnProcess(Self,APosition);
end;

{ TSpeechParam }

class operator TSpeechParam.Initialize(out Dest: TSpeechParam);
begin
  Dest.SoundType := SndBase64;
  Dest.Encoding := 'FLAC';
  Dest.RateHertz := 48000;
  Dest.Language := 'tr';
  Dest.AudioChannelCount := 2;
  Dest.SoundSource := '';
  Dest.LongSoundPost := False;
end;

{ TSpeechResult }

class operator TSpeechResult.Initialize(out Dest: TSpeechResult);
begin
  Dest.ErrorStr := '';
  Dest.Error := False;
  Dest.TextArr := [];
end;

end.

