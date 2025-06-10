codeunit 80100 "EE Alvys Mgt."
{
    var
        AlvysSetup: Record "EE Alvys Setup";
        // RestAPIMgt: Codeunit "EE REST API Mgt.";
        JsonMgt: Codeunit "EE Json Mgt.";


    local procedure GetAndCheckSetup()
    begin
        AlvysSetup.Get();
        AlvysSetup.TestField("Integration URL");
        AlvysSetup.TestField("Tenant ID");
        AlvysSetup.TestField("Client ID");
        AlvysSetup.TestField("Client Secret");
    end;

    procedure CheckToGetAPIToken(): Text
    var
        ResponseText: Text;
    begin
        GetAndCheckSetup();
        if (AlvysSetup."API Token" <> '') and (AlvysSetup."API Token Expiry DateTime" >= CurrentDateTime()) then
            exit(AlvysSetup."API Token");
        exit(CheckToGetAPIToken(AlvysSetup));
    end;

    procedure CheckToGetAPIToken(var AlvysSetup: Record "EE Alvys Setup"): Text
    var
        JsonTkn: JsonToken;
        JsonBody: JsonObject;
        HourDelay: Duration;
        SendTime: DateTime;
        FormData: Dictionary of [Text, Text];
        URL, s : Text;
    begin
        SendTime := CurrentDateTime();
        URL := StrSubstNo('%1/api/authentication/%2/token', AlvysSetup."Integration URL", AlvysSetup."Tenant ID");




        JsonBody.Add('client_id', AlvysSetup."Client ID");
        JsonBody.Add('client_secret', AlvysSetup."Client Secret");
        JsonBody.Add('grant_type', 'client_credentials');

        JsonBody.WriteTo(s);
        if not Confirm('%1\%2', false, URL, s) then
            Error('');

        JsonTkn := GetResponseAsJsonToken('POST', URL, 'access_token', JsonBody);

        JsonTkn.WriteTo(s);
        if not Confirm('recieved: %1', false, s) then
            Error('');

        if JsonTkn.WriteTo(AlvysSetup."API Token") then begin
            HourDelay := 3600;
            AlvysSetup.Validate("API Token", AlvysSetup."API Token".Replace('"', ''));
            AlvysSetup.Validate("API Token Expiry DateTime", SendTime + HourDelay);
            AlvysSetup.Modify(true);
            exit(AlvysSetup."API Token");
        end;
    end;


    procedure GetResponseAsJsonToken(Method: Text; URL: Text; TokenName: Text; JsonBody: JsonObject): Variant
    var
        ResponseText, ReasonPhrase : Text;
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        Sent: Boolean;
    begin
        ClearLastError();
        Sent := SendRequestWithJsonBody(Method, URL, JsonBody, ResponseText, ReasonPhrase);

        if not Sent then
            if ResponseText <> '' then
                Error(ResponseText)
            else
                if ReasonPhrase <> '' then
                    Error('Failed to send request:\%1', ReasonPhrase)
                else
                    Error('Failed to send request:\%1', GetLastErrorText());
        if not JsonObj.ReadFrom(ResponseText) then
            Error('Unable to read response:\%1', ResponseText);
        if not JsonObj.Get(TokenName, JsonTkn) then begin
            JsonObj.WriteTo(ResponseText);
            if ResponseText.Contains('"result":"error"') then
                Error(ResponseText);
            Error('Token %1 not found in response:\%2', TokenName, ResponseText);
        end;
        exit(JsonTkn);
    end;

    local procedure SendRequestWithJsonBody(Method: Text; URL: Text; var JsonObj: JsonObject; var ResponseText: Text; var ReasonPhrase: Text): Boolean
    var
        Content: HttpContent;
        s: Text;
    begin
        JsonObj.WriteTo(s);
        Content.WriteFrom(s);
        exit(SendRequest(Method, URL, ResponseText, Content, StrLen(s), ReasonPhrase));
    end;

    local procedure SendRequest(Method: Text; URL: Text; var ResponseText: Text; var Content: HttpContent; ContentLength: Integer; var ReasonPhrase: Text): Boolean
    var
        HttpClient: HttpClient;
        Headers: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        ContentType: Text;

        cookies: List of [Text];
        s: Text;
        Debug: TextBuilder;

    // c1: Codeunit c
    begin
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method(Method);



        if (Method <> 'GET') and (ContentLength > 0) then begin
            HttpRequestMessage.Content(Content);
            HttpRequestMessage.GetHeaders(Headers);
            Headers.Clear();
            Headers.Add('Host', 'integrations.alvys.com');
            Headers.Add('Accept', '*/*');

            Content.GetHeaders(Headers);
            Headers.Clear();
            ContentType := 'application/json';
            Headers.Add('Content-Type', ContentType);
            Headers.Add('Content-Length', Format(ContentLength));



            Debug.AppendLine('Request Headers');
            Debug.AppendLine(StrSubstNo('%1: %2', 'Host', 'integrations.alvys.com'));
            Debug.AppendLine(StrSubstNo('%1: %2', 'Accept', '*/*'));
            Debug.AppendLine(StrSubstNo('%1: %2', 'Content-Type', ContentType));
            Debug.AppendLine(StrSubstNo('%1: %2', 'Content-Length', Format(ContentLength)));

            Message(Debug.ToText());
            // Content.ReadAs(s);
            // Error(s);





            // HttpRequestMessage.GetHeaders(Headers);
            // if not Confirm(PrintHeaders(Headers, 'Request Headers')) then
            //     Error('');
            // Content.GetHeaders(Headers);
            // if not Confirm(PrintHeaders(Headers, 'Request Content Headers')) then
            //     Error('');
        end;


        HttpClient.UseResponseCookies(false);
        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            ResponseText := StrSubstNo('Unable to send request:\%1', GetLastErrorText());
            exit(false);
        end;

        // Error('');

        // HttpRequestMessage.cook
        HttpResponseMessage.Content().ReadAs(ResponseText);
        ReasonPhrase := HttpResponseMessage.ReasonPhrase;

        if not Confirm('%1\%2', false, ReasonPhrase, ResponseText) then
            Error('');

        exit(HttpResponseMessage.IsSuccessStatusCode());
    end;


    local procedure PrintHeaders(var Headers: HttpHeaders; Title: Text): Text
    var
        keys, values : List of [Text];
        s, s2 : Text;
        DebugText: TextBuilder;
    begin
        DebugText.AppendLine(Title);
        DebugText.AppendLine('');
        keys := Headers.Keys();
        foreach s in keys do begin
            Clear(values);
            Headers.GetValues(s, values);
            DebugText.AppendLine(s);
            foreach s2 in values do
                DebugText.AppendLine(StrSubstNo('  %1', s2));
        end;
        // if not Confirm(DebugText.ToText()) then
        //     Error('');
        exit(DebugText.ToText());
    end;
}