codeunit 80004 "EE REST API Mgt."
{
    procedure GetResponseAsJsonToken(URL: Text; TokenName: Text): Variant
    var
        ResponseText: Text;
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
    begin
        if not SendRequest('GET', URL, ResponseText) then
            Error(ResponseText);
        JsonObj.ReadFrom(ResponseText);
        if not JsonObj.Get(TokenName, JsonTkn) then begin
            JsonObj.WriteTo(ResponseText);
            if ResponseText.Contains('"result":"error"') then
                Error(ResponseText);
            Error('Token %1 not found in response:\%2', TokenName, ResponseText);
        end;
        exit(JsonTkn);
    end;

    procedure GetResponseWithFormDataBodyAsJsonToken(Method: Text; URL: Text; TokenName: Text; var ContentBody: TextBuilder): Variant
    var
        ResponseText: Text;
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
    begin
        if not SendRequestWithFormDataBody(Method, URL, ContentBody, ResponseText) then
            Error(ResponseText);
        JsonObj.ReadFrom(ResponseText);
        if not JsonObj.Get(TokenName, JsonTkn) then begin
            JsonObj.WriteTo(ResponseText);
            if ResponseText.Contains('"result":"error"') then
                Error(ResponseText);
            Error('Token %1 not found in response:\%2', TokenName, ResponseText);
        end;
        exit(JsonTkn);
    end;

    procedure GetResponseWithJsonBodyAsJsonToken(Method: Text; URL: Text; TokenName: Text; var JsonBody: JsonObject): Variant
    var
        ResponseText: Text;
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
    begin
        // if not SendRequestWithFormDataBody(Method, URL, ContentBody, ResponseText) then
        if not SendRequestWithJsonBody(Method, URL, JsonBody, ResponseText, true) then
            Error(ResponseText);
        JsonObj.ReadFrom(ResponseText);
        if not JsonObj.Get(TokenName, JsonTkn) then begin
            JsonObj.WriteTo(ResponseText);
            if ResponseText.Contains('"result":"error"') then
                Error(ResponseText);
            Error('Token %1 not found in response:\%2', TokenName, ResponseText);
        end;
        exit(JsonTkn);
    end;


    procedure GetResponseAsJsonArray(URL: Text; TokenName: Text): Variant
    var
        JsonBody: JsonObject;
    begin
        exit(GetResponseAsJsonArray(URL, TokenName, 'GET', JsonBody));
    end;

    [TryFunction]
    procedure TryToGetResponseAsJsonArray(URL: Text; TokenName: Text; Method: Text; var JsonBody: JsonObject; var ResponseArray: JsonArray)
    begin
        ResponseArray := GetResponseAsJsonArray(URL, TokenName, Method, JsonBody);
    end;

    procedure GetResponseAsJsonArray(URL: Text; TokenName: Text; Method: Text; var JsonBody: JsonObject): Variant
    var
        ResponseText: Text;
        JsonObj: JsonObject;
        JsonArry: JsonArray;
        JsonTkn: JsonToken;
        Result, Sent : Boolean;
    begin
        if JsonBody.Keys.Count() > 0 then
            Sent := SendRequestWithJsonBody(Method, URL, JsonBody, ResponseText)
        else
            Sent := SendRequest(Method, URL, ResponseText);
        if not Sent then
            Error(ResponseText);

        JsonObj.ReadFrom(ResponseText);
        if not JsonObj.Get(TokenName, JsonTkn) then begin
            JsonObj.WriteTo(ResponseText);
            if ResponseText.Contains('"result":"error"') then
                Error(ResponseText);
            Error('Token %1 not found in response:\%2', TokenName, ResponseText);
        end;
        JsonArry := JsonTkn.AsArray();
        exit(JsonArry);
    end;

    local procedure SendRequestWithJsonBody(Method: Text; URL: Text; var JsonObj: JsonObject; var ResponseText: Text): Boolean
    begin
        exit(SendRequestWithJsonBody(Method, URL, JsonObj, ResponseText, false));
    end;

    local procedure SendRequestWithJsonBody(Method: Text; URL: Text; var JsonObj: JsonObject; var ResponseText: Text; UseBoundary: Boolean): Boolean
    var
        Content: HttpContent;
        s: Text;
    begin
        JsonObj.WriteTo(s);
        Content.WriteFrom(s);
        exit(SendRequest(Method, URL, ResponseText, Content, StrLen(s), UseBoundary));
    end;

    local procedure SendRequestWithFormDataBody(Method: Text; URL: Text; var ContentBody: TextBuilder; var ResponseText: Text): Boolean
    var
        Content: HttpContent;
    begin
        Content.WriteFrom(ContentBody.ToText());
        exit(SendRequest(Method, URL, ResponseText, Content, ContentBody.Length(), true));
    end;

    local procedure SendRequest(Method: Text; URL: Text; var ResponseText: Text): Boolean
    var
        Content: HttpContent;
    begin
        exit(SendRequest(Method, URL, ResponseText, Content, 0));
    end;

    local procedure SendRequest(Method: Text; URL: Text; var ResponseText: Text; var Content: HttpContent; ContentLength: Integer): Boolean
    begin
        SendRequest(Method, URL, ResponseText, Content, ContentLength, false);
    end;

    local procedure SendRequest(Method: Text; URL: Text; var ResponseText: Text; var Content: HttpContent; ContentLength: Integer; UseBoundary: Boolean): Boolean
    var
        HttpClient: HttpClient;
        Headers: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        ContentText: TextBuilder;
        Boundary: Integer;
        s: Text;
    begin
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method(Method);

        if (Method <> 'GET') and (ContentLength > 0) then
            if UseBoundary then begin

                // Content.GetHeaders(Headers);
                // AddHeader(Headers, 'Content-Type', 'multipart/form-data; boundary=boundary');
                // AddHeader(Headers, 'Content-Length', Format(ContentLength));

                Randomize(ContentLength);
                Boundary := Random(999999999);
                while Boundary < 100000000 do
                    Boundary := Boundary * 10 + Random(10) - 1;

                ContentText.AppendLine(StrSubstNo('--%1', Boundary));
                ContentText.AppendLine('Content-Type: application/json');
                ContentText.AppendLine('');
                Content.ReadAs(s);
                ContentText.AppendLine(s);
                ContentText.AppendLine(StrSubstNo('--%1--', Boundary));
                Content.WriteFrom(ContentText.ToText());

                Content.ReadAs(s);
                if not Confirm(s) then
                    Error('');

                HttpRequestMessage.Content(Content);
                Content.GetHeaders(Headers);
                AddHeader(Headers, 'Content-Type', StrSubstNo('multipart/form-data; boundary="%1"', Boundary));
                AddHeader(Headers, 'Content-Length', Format(ContentText.Length()));
                HttpRequestMessage.GetHeaders(Headers);
                AddHeader(Headers, 'Host', 'integrations.alvys.com');
            end else begin
                HttpRequestMessage.Content(Content);
                Content.GetHeaders(Headers);
                AddHeader(Headers, 'Content-Type', 'application/json');
                AddHeader(Headers, 'Content-Length', Format(ContentLength));
            end;

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin

            if not Confirm('failed') then
                Error('');

            ResponseText := StrSubstNo('Unable to send request:\%1', GetLastErrorText());
            exit(false);
        end;

        HttpResponseMessage.Content().ReadAs(ResponseText);
        exit(HttpResponseMessage.IsSuccessStatusCode());
    end;

    local procedure AddHeader(var Headers: HttpHeaders; KeyName: Text; ValueName: Text)
    begin
        if Headers.Contains(KeyName) then
            Headers.Remove(KeyName);
        Headers.Add(KeyName, ValueName);
    end;
}