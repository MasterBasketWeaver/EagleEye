codeunit 80020 "EE Codeunit Test"
{
    var
        AlvysSetup: Record "EE Alvys Setup";
        RestAPIMgt: Codeunit "EE REST API Mgt.";
        JsonMgt: Codeunit "EE Json Mgt.";

    procedure TestAPICall()
    var
        FormData: Dictionary of [Text, Text];
        ResponseText: Text;
        URL: Text;
    begin
        GetAndCheckSetup();
        URL := StrSubstNo('%1/api/authentication/%2/token', AlvysSetup."Integration URL", AlvysSetup."Tenant ID");

        FormData.Add('tenant_id', AlvysSetup."Tenant ID");
        FormData.Add('client_id', AlvysSetup."Client ID");
        FormData.Add('client_secret', AlvysSetup."Client Secret");
        FormData.Add('grant_type', 'client_credentials');

        if SendFormDataRequest('POST', URL, FormData, ResponseText) then
            Message('Success: %1', ResponseText)
        else
            Error('Error: %1', ResponseText);
    end;

    local procedure GetAndCheckSetup()
    begin
        AlvysSetup.Get();
        AlvysSetup.TestField("Integration URL");
        AlvysSetup.TestField("Tenant ID");
        AlvysSetup.TestField("Client ID");
        AlvysSetup.TestField("Client Secret");
    end;

    local procedure SendFormDataRequest(Method: Text; URL: Text; var FormData: Dictionary of [Text, Text]; var ResponseText: Text): Boolean
    var
        HttpClient: HttpClient;
        Headers: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        ContentText: TextBuilder;
        FormKey: Text;
        FormValue: Text;
        Boundary: Text;
    begin
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method(Method);

        // Generate a unique boundary
        Boundary := '----WebKitFormBoundary' + Format(CreateGuid());

        // Build the multipart form data
        foreach FormKey in FormData.Keys do begin
            if FormKey <> 'tenant_id' then begin  // Skip tenant_id as it's in the URL
                FormData.Get(FormKey, FormValue);
                ContentText.Append('--' + Boundary);
                ContentText.AppendLine();
                ContentText.Append('Content-Disposition: form-data; name="' + FormKey + '"');
                ContentText.AppendLine();
                ContentText.Append(FormValue);
                ContentText.AppendLine();
            end;
        end;
        ContentText.Append('--' + Boundary + '--');

        // Set the content
        Content.WriteFrom(ContentText.ToText());
        HttpRequestMessage.Content(Content);

        // Set Content-Type header
        Content.GetHeaders(Headers);
        AddHeader(Headers, 'Content-Type', StrSubstNo('multipart/form-data; boundary="%1"', Boundary));  // Removed quotes around boundary

        // Show debugging information
        Message('Request Details:\' +
                'URL: %1\' +
                'Method: %2\' +
                'Content-Type: %3\' +
                'Request Body:\%4',
                URL, Method, StrSubstNo('multipart/form-data; boundary=%1', Boundary), ContentText.ToText());

        // Send the request
        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            ResponseText := StrSubstNo('Unable to send request:\%1', GetLastErrorText());
            exit(false);
        end;

        HttpResponseMessage.Content().ReadAs(ResponseText);
        exit(HttpResponseMessage.IsSuccessStatusCode());
    end;

    local procedure UrlEncode(TextToEncode: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        EncodedText: Text;
    begin
        EncodedText := TypeHelper.UrlEncode(TextToEncode);
        exit(EncodedText);
    end;

    local procedure AddHeader(var Headers: HttpHeaders; KeyName: Text; ValueName: Text)
    begin
        if Headers.Contains(KeyName) then
            Headers.Remove(KeyName);
        Headers.Add(KeyName, ValueName);
    end;
}