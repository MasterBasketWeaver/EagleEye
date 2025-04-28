codeunit 80300 "EEMCP My Carrier Packets Mgt."
{
    var
        MyCarrierPacketsSetup: Record "EEMCP MyCarrierPackets Setup";


    local procedure GetAndCheckSetup()
    begin
        MyCarrierPacketsSetup.Get();
        MyCarrierPacketsSetup.TestField("Integration URL");
        MyCarrierPacketsSetup.TestField(Username);
        MyCarrierPacketsSetup.TestField(Password);
    end;

    procedure CheckToGetAPIToken(): Text
    var
        ResponseText: Text;
    begin
        GetAndCheckSetup();
        if (MyCarrierPacketsSetup."API Token" <> '') and (MyCarrierPacketsSetup."API Token Expiry DateTime" >= CurrentDateTime()) then
            exit(MyCarrierPacketsSetup."API Token");
        exit(CheckToGetAPIToken(MyCarrierPacketsSetup));
    end;



    procedure CheckToGetAPIToken(var MyCarrierPacketsSetup: Record "EEMCP MyCarrierPackets Setup"): Text
    var
        FormData: Dictionary of [Text, Text];
        JsonTkn: JsonToken;
        ResponseBody: JsonObject;
        Expires: DateTime;
        URL, s : Text;
    begin
        URL := StrSubstNo('%1/token', MyCarrierPacketsSetup."Integration URL");

        FormData.Add('grant_type', 'password');
        FormData.Add('username', MyCarrierPacketsSetup.Username);
        FormData.Add('password', MyCarrierPacketsSetup.Password);

        ResponseBody := GetResponseWithEncodedFormDataBodyAsJsonObject('POST', URL, FormData);
        if ResponseBody.Get('access_token', JsonTkn) then begin
            JsonTkn.WriteTo(s);
            MyCarrierPacketsSetup.Validate("API Token", s.Replace('"', ''));
        end else
            Error('Token %1 not found in response:\%2', 'access_token', ResponseBody);
        if ResponseBody.Get('refresh_token', JsonTkn) then begin
            JsonTkn.WriteTo(s);
            MyCarrierPacketsSetup.Validate("API Refresh Token", s.Replace('"', ''));
        end;
        if ResponseBody.Get('.expires', JsonTkn) then begin
            JsonTkn.WriteTo(s);
            if Evaluate(Expires, s.Replace('"', '')) then
                MyCarrierPacketsSetup.Validate("API Token Expiry DateTime", Expires);
        end;


        exit(MyCarrierPacketsSetup."API Token");
    end;



    procedure GetResponseWithEncodedFormDataBodyAsJsonObject(Method: Text; URL: Text; var FormData: Dictionary of [Text, Text]): Variant
    var
        ResponseText: Text;
        JsonObj: JsonObject;
    begin
        if not SendEncodedFormDataRequest(Method, URL, FormData, ResponseText) then
            Error(ResponseText);
        JsonObj.ReadFrom(ResponseText);
        exit(JsonObj);
    end;

    local procedure SendEncodedFormDataRequest(Method: Text; URL: Text; var FormData: Dictionary of [Text, Text]; var ResponseText: Text): Boolean
    var

        HttpClient: HttpClient;
        Headers: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        ContentText: TextBuilder;
        Boundary: Integer;
        FormKey: Text;
        FormValue: Text;
        i, ContentCount : Integer;

    begin
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method(Method);

        ContentText.Append(StrSubstNo('%1=%2', FormData.Keys.Get(1), Encode(FormData.Values.Get(1))));
        if FormData.Count() > 1 then
            for i := 2 to FormData.Count() do
                ContentText.Append(StrSubstNo('&%1=%2', FormData.Keys.Get(i), Encode(FormData.Values.Get(i))));

        Content.WriteFrom(ContentText.ToText());
        HttpRequestMessage.Content(Content);

        Content.GetHeaders(Headers);
        AddHeader(Headers, 'charset', 'UTF-8');
        AddHeader(Headers, 'Content-Type', 'application/x-www-form-urlencoded');

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            ResponseText := StrSubstNo('Unable to send request:\%1', GetLastErrorText());
            exit(false);
        end;

        HttpResponseMessage.Content().ReadAs(ResponseText);
        exit(HttpResponseMessage.IsSuccessStatusCode());
    end;


    local procedure Encode(Input: Text): Text
    begin
        exit(TypeHelper.UrlEncode(Input));
    end;

    local procedure AddHeader(var Headers: HttpHeaders; KeyName: Text; ValueName: Text)
    begin
        if Headers.Contains(KeyName) then
            Headers.Remove(KeyName);
        Headers.Add(KeyName, ValueName);
    end;





    var
        TypeHelper: Codeunit "Type Helper";
}