unit Controller.Messages;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Serializer.Commons,
  Web.HTTPApp;

type

  [MVCPath('/api')]
  TControllerMessages = class(TMVCController) 
    public
    [MVCPath('/messages/receive')]
    [MVCHTTPMethod([httpPOST])]
    procedure Receive(WebContext : TWebContext);
    procedure SendResponse(ResponseFrom, ResponseTo, ResponseText : String);
  end;

const
  ACCOUNT_SID = '';
  AUTH_TOKEN  = '';
  SOURCE_NUMBER = '+PUT YOUR PHONE NUMBER HERE';

implementation

uses
  System.SysUtils, MVCFramework.Logger, System.StrUtils, System.JSON,
  System.NetEncoding, System.Classes, uTwilioClient;

procedure TControllerMessages.Receive(WebContext : TWebContext);
var
  aMessage  : TStrings;
  aResponse : String;
begin
  WriteLn('Raw Data: ');
  WriteLn(WebContext.Request.Body);
  
  aMessage := TStringList.Create;
  try
    aMessage.Delimiter     := '&';
    aMessage.DelimitedText := WebContext.Request.Body;

    // Decoding the text received
    aMessage.Text := TNetEncoding.URL.Decode(aMessage.Text);
    
    WriteLn('Data: ');
    WriteLn(aMessage.text);

    // Creating the response for the received message
    if aMessage.Values['Body'].Trim.ToLower = 'ping' then
      aResponse := 'pong'
    else
      aResponse := ReverseString(aMessage.Values['Body']);

    SendResponse(aMessage.Values['To'], aMessage.Values['From'], aResponse);
    
  finally
    aMessage.Free;
  end;
end;

procedure TControllerMessages.SendResponse(ResponseFrom, ResponseTo, ResponseText : String);
var
  TwilioClient : TTwilioClient;
  Params       : TStrings;
begin
  if ((ACCOUNT_SID = '') or (AUTH_TOKEN = '')) then
    raise Exception.Create('Please, inform your ACCOUNT SID AND YOUR AUTH TOKEN')
  else begin
    TwilioClient := TTwilioClient.Create(ACCOUNT_SID, AUTH_TOKEN);
    try
      Params := TStringList.Create;
      try
        Params.Add('From=' + ResponseFrom);
        Params.Add('To='+ ResponseTo);
        Params.Add('Body=' + ResponseText);

        TwilioClient.Post('Messages', Params);
      finally
        Params.Free;
      end;
    finally
      TwilioClient.Free;
    end;
  end;
end;

end.
