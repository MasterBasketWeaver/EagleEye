codeunit 80303 "EEMCP REST API Mgt."
{
    var
        TypeHelper: Codeunit "Type Helper";
        JsonTypeGlobal: Option "Token","Object";


    procedure GetResponseAsJsonToken(Method: Text; URL: Text; TokenName: Text): Variant
    var
        JsonBody: JsonObject;
        Headers: HttpHeaders;
    begin
        exit(GetResponseAsJsonToken(Method, URL, TokenName, JsonBody, Headers));
    end;

    procedure GetResponseAsJsonToken(Method: Text; URL: Text; TokenName: Text; var JsonBody: JsonObject): Variant
    var
        Headers: HttpHeaders;
    begin
        exit(GetResponseAsJsonToken(Method, URL, TokenName, JsonBody, Headers));
    end;

    procedure GetResponseAsJsonToken(Method: Text; URL: Text; TokenName: Text; var PassedHeaders: HttpHeaders): Variant
    var
        JsonBody: JsonObject;
    begin
        exit(GetResponseAsJsonToken(Method, URL, TokenName, JsonBody, PassedHeaders));
    end;

    procedure GetResponseAsJsonToken(Method: Text; URL: Text; TokenName: Text; var JsonBody: JsonObject; var PassedHeaders: HttpHeaders): Variant
    begin
        exit(GetResponseAsJson(Method, URL, TokenName, JsonBody, PassedHeaders, JsonTypeGlobal::Token));
    end;

    procedure GetResponseAsJsonObject(Method: Text; URL: Text; TokenName: Text; var JsonBody: JsonObject; var PassedHeaders: HttpHeaders): Variant
    begin
        exit(GetResponseAsJson(Method, URL, TokenName, JsonBody, PassedHeaders, JsonTypeGlobal::Object));
    end;

    procedure GetResponseAsJson(Method: Text; URL: Text; TokenName: Text; var JsonBody: JsonObject; var PassedHeaders: HttpHeaders; JsonType: Option "Token","Object"): Variant
    var
        ResponseText, ReasonPhrase : Text;
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
    begin
        ChooseRequestToSend(Method, URL, JsonBody, PassedHeaders, ResponseText, ReasonPhrase);
        if not JsonObj.ReadFrom(ResponseText) then
            if ResponseText <> '' then
                Error(ResponseText)
            else
                Error(ReasonPhrase);
        case JsonType of
            JsonType::Token:
                begin
                    if TokenName = '' then
                        exit(JsonObj.AsToken());
                    if not JsonObj.Get(TokenName, JsonTkn) then begin
                        JsonObj.WriteTo(ResponseText);
                        if ResponseText.Contains('"result":"error"') then
                            Error(ResponseText);
                        Error('Token %1 not found in response:\%2', TokenName, ResponseText);
                    end;
                    exit(JsonTkn);
                end;
            JsonType::Object:
                exit(JsonObj);
        end;
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
        Headers: HttpHeaders;
    begin
        exit(GetResponseAsJsonArray(URL, TokenName, Method, JsonBody, Headers));
    end;

    //used by MCP app
    procedure GetResponseAsJsonArray(URL: Text; Method: Text; var PassedHeaders: HttpHeaders): Variant
    var
        JsonBody: JsonObject;
        TokenName: Text;
    begin
        exit(GetResponseAsJsonArray(URL, TokenName, Method, JsonBody, PassedHeaders));
    end;

    procedure GetResponseAsJsonArray(URL: Text; TokenName: Text; Method: Text; var JsonBody: JsonObject; var PassedHeaders: HttpHeaders): Variant
    var
        ResponseText, ReasonPhrase : Text;
        JsonObj: JsonObject;
        JsonArry: JsonArray;
        JsonTkn: JsonToken;
    begin
        ChooseRequestToSend(Method, URL, JsonBody, PassedHeaders, ResponseText, ReasonPhrase);

        if JsonArry.ReadFrom(ResponseText) then
            exit(JsonArry);

        if not JsonObj.ReadFrom(ResponseText) then
            if ResponseText <> '' then
                Error(ResponseText)
            else
                Error(ReasonPhrase);
        if TokenName <> '' then begin
            if not JsonObj.Get(TokenName, JsonTkn) then begin
                JsonObj.WriteTo(ResponseText);
                if ResponseText <> '' then begin
                    if ResponseText.Contains('"result":"error"') then
                        Error(ResponseText);
                    Error('Token %1 not found in response:\%2', TokenName, ResponseText);
                end else
                    Error(ReasonPhrase);
            end;
            JsonArry := JsonTkn.AsArray();
        end else
            JsonArry := JsonObj.AsToken().AsArray();
        exit(JsonArry);
    end;


    local procedure ChooseRequestToSend(Method: Text; URL: Text; var JsonBody: JsonObject; var PassedHeaders: HttpHeaders; var ResponseText: Text; var ReasonPhrase: Text): Boolean
    var
        HaveHeaders, HasBody, Sent : Boolean;
    begin
        HaveHeaders := PassedHeaders.Keys().Count() > 0;
        HasBody := JsonBody.Keys.Count() > 0;

        if HasBody then
            if HaveHeaders then
                Sent := SendRequestWithJsonBody(Method, URL, JsonBody, PassedHeaders, ResponseText, ReasonPhrase)
            else
                Sent := SendRequestWithJsonBody(Method, URL, JsonBody, ResponseText, ReasonPhrase)
        else
            if HaveHeaders then
                Sent := SendRequest(Method, URL, ResponseText, ReasonPhrase, PassedHeaders)
            else
                Sent := SendRequest(Method, URL, ResponseText, ReasonPhrase);
        if not Sent then
            if ResponseText <> '' then
                Error(ResponseText)
            else
                Error(ReasonPhrase);
    end;



    local procedure SendRequestWithJsonBody(Method: Text; URL: Text; var JsonBody: JsonObject; var ResponseText: Text; var ReasonPhrase: Text): Boolean
    var
        Headers: HttpHeaders;
    begin
        exit(SendRequestWithJsonBody(Method, URL, JsonBody, Headers, ResponseText, ReasonPhrase));
    end;

    local procedure SendRequestWithJsonBody(Method: Text; URL: Text; var JsonBody: JsonObject; var PassedHeaders: HttpHeaders; var ResponseText: Text; var ReasonPhrase: Text): Boolean
    var
        Content: HttpContent;
        s: Text;
    begin
        JsonBody.WriteTo(s);
        Content.WriteFrom(s);
        exit(SendRequest(Method, URL, ResponseText, ReasonPhrase, Content, PassedHeaders, StrLen(s)));
    end;





    local procedure SendRequest(Method: Text; URL: Text; var ResponseText: Text): Boolean
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        ReasonPhrase: Text;
    begin
        exit(SendRequest(Method, URL, ResponseText, ReasonPhrase, Content, Headers, 0));
    end;

    local procedure SendRequest(Method: Text; URL: Text; var ResponseText: Text; var ReasonPhrase: Text): Boolean
    var
        Content: HttpContent;
        Headers: HttpHeaders;
    begin
        exit(SendRequest(Method, URL, ResponseText, ReasonPhrase, Content, Headers, 0));
    end;

    local procedure SendRequest(Method: Text; URL: Text; var ResponseText: Text; var ReasonPhrase: Text; var PassedHeaders: HttpHeaders): Boolean
    var
        Content: HttpContent;
    begin
        exit(SendRequest(Method, URL, ResponseText, ReasonPhrase, Content, PassedHeaders, 0));
    end;

    local procedure SendRequest(Method: Text; URL: Text; var ResponseText: Text; var ReasonPhrase: Text; var Content: HttpContent; var PassedHeaders: HttpHeaders; ContentLength: Integer): Boolean
    var
        HttpClient: HttpClient;
        RequestHeaders, ContentHeaders : HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HeaderKeys, HeaderValues : List of [Text];
        HeaderKey: Text;
        PassedHeaderCount, i : Integer;
    begin
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method(Method);

        PassedHeaderCount := PassedHeaders.Keys().Count();
        if PassedHeaderCount > 0 then begin
            HttpRequestMessage.GetHeaders(RequestHeaders);
            if PassedHeaderCount > 0 then
                foreach HeaderKey in PassedHeaders.Keys() do
                    if PassedHeaders.GetValues(HeaderKey, HeaderValues) then
                        AddHeader(RequestHeaders, HeaderKey, HeaderValues.Get(1));
        end;

        if (Method <> 'GET') and (ContentLength > 0) then begin
            HttpRequestMessage.Content(Content);
            Content.GetHeaders(ContentHeaders);
            AddHeader(ContentHeaders, 'Content-Type', 'application/json');
            AddHeader(ContentHeaders, 'Content-Length', Format(ContentLength));
        end;

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            ResponseText := StrSubstNo('Unable to send request:\%1', GetLastErrorText());
            exit(false);
        end;

        HttpResponseMessage.Content().ReadAs(ResponseText);
        ReasonPhrase := HttpResponseMessage.ReasonPhrase();
        exit(HttpResponseMessage.IsSuccessStatusCode());
    end;

    procedure AddHeader(var Headers: HttpHeaders; KeyName: Text; ValueName: Text)
    begin
        if Headers.Contains(KeyName) then
            Headers.Remove(KeyName);
        Headers.Add(KeyName, ValueName);
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
        i: Integer;
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
}