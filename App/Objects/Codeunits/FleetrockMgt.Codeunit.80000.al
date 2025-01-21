codeunit 80000 "EE Fleetrock Mgt."
{
    [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterInsertEvent, '', false, false)]
    local procedure GLAccountOnAfterInsert(var Rec: Record "G/L Account")
    begin
        SyncGLToFleetRock(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterModifyEvent, '', false, false)]
    local procedure GLAccountOnAfterModify(var Rec: Record "G/L Account")
    begin
        SyncGLToFleetRock(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterDeleteEvent, '', false, false)]
    local procedure GLAccountOnAfterDelete(var Rec: Record "G/L Account")
    begin
        SyncGLToFleetRock(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterRenameEvent, '', false, false)]
    local procedure GLAccountOnRenameDelete(var Rec: Record "G/L Account")
    begin
        SyncGLToFleetRock(Rec, false);
    end;

    procedure SyncGLToFleetRock(var GLAccount: Record "G/L Account"; Deleted: Boolean)
    begin

    end;


    procedure CheckToGetAPIToken(): Text
    var
        FleetrockSetup: Record "EE Fleetrock Setup";
        ResponseText: Text;
    begin
        FleetrockSetup.Get();
        FleetrockSetup.TestField("Integration URL");
        FleetrockSetup.TestField("Username");
        FleetrockSetup.TestField("API Key");
        if FleetrockSetup."API Token" <> '' then
            exit(FleetrockSetup."API Token");
        exit(CheckToGetAPIToken(FleetrockSetup));
    end;

    procedure CheckToGetAPIToken(var FleetrockSetup: Record "EE Fleetrock Setup"): Text
    var
        ResponseText: Text;
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
    begin
        if not SendRequest('GET', StrSubstNo('%1/API/GetToken?username=%2&key=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, FleetrockSetup."API Key"), ResponseText) then
            Error(ResponseText);
        JsonObj.ReadFrom(ResponseText);
        if not JsonObj.Get('token', JsonTkn) then begin
            JsonObj.WriteTo(ResponseText);
            Error('Token not found in response:\%1', ResponseText);
        end;
        JsonTkn.WriteTo(FleetrockSetup."API Token");
        FleetrockSetup.Validate("API Token", FleetrockSetup."API Token".Replace('"', ''));
        FleetrockSetup.Modify(true);
        exit(FleetrockSetup."API Token");
    end;

    procedure SendRequest(Method: Text; URL: Text; var ResponseText: Text): Boolean
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
    begin
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method(Method);

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            ResponseText := StrSubstNo('Unable to send request:\%1', GetLastErrorText());
            exit(false);
        end;

        HttpResponseMessage.Content().ReadAs(ResponseText);
        exit(HttpResponseMessage.IsSuccessStatusCode());
    end;


    // procedure SendRequest(Method: Text; URL: Text): Boolean
    // var
    //     HttpClient: HttpClient;
    //     HttpRequestMessage: HttpRequestMessage;
    //     HttpResponseMessage: HttpResponseMessage;
    //     ContentHeaders: HttpHeaders;
    //     HttpContent: HttpContent;
    //     ResponseText: Text;
    //     ErrorBodyContent: Text;
    //     TextContent: Text;
    //     InStreamContent: InStream;
    //     i: Integer;
    //     KeyVariant: Variant;
    //     ValueVariant: Variant;
    //     HasContent: Boolean;
    // begin
    //     case true of
    //         contentToSendVariant.IsText():
    //             begin
    //                 TextContent := contentToSendVariant;
    //                 if TextContent <> '' then begin
    //                     HttpContent.WriteFrom(TextContent);
    //                     HasContent := true;
    //                 end;
    //             end;
    //         contentToSendVariant.IsInStream():
    //             begin
    //                 InStreamContent := contentToSendVariant;
    //                 HttpContent.WriteFrom(InStreamContent);
    //                 HasContent := true;
    //             end;
    //         else
    //             Error(UnsupportedContentToSendErr);
    //     end;

    //     if HasContent then
    //         HttpRequestMessage.Content := HttpContent;

    //     if ContentType <> '' then begin
    //         ContentHeaders.Clear();
    //         HttpRequestMessage.Content.GetHeaders(ContentHeaders);
    //         if ContentHeaders.Contains(ContentTypeKeyLbl) then
    //             ContentHeaders.Remove(ContentTypeKeyLbl);

    //         ContentHeaders.Add(ContentTypeKeyLbl, ContentType);
    //     end;

    //     for i := 0 to DictionaryWrapperContentHeaders.Count() do
    //         if DictionaryWrapperContentHeaders.TryGetKeyValue(i, KeyVariant, ValueVariant) then
    //             ContentHeaders.Add(Format(KeyVariant), Format(ValueVariant));

    //     HttpRequestMessage.SetRequestUri(requestUri);
    //     HttpRequestMessage.Method := Format(RequestMethod);

    //     for i := 0 to DictionaryWrapperDefaultHeaders.Count() do
    //         if DictionaryWrapperDefaultHeaders.TryGetKeyValue(i, KeyVariant, ValueVariant) then
    //             HttpClient.DefaultRequestHeaders.Add(Format(KeyVariant), Format(ValueVariant));

    //     if HttpTimeout <> 0 then
    //         HttpClient.Timeout(HttpTimeout);

    //     HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

    //     HttpResponseMessage.Content().ReadAs(ResponseText);
    //     if not HttpResponseMessage.IsSuccessStatusCode() then begin
    //         HttpResponseMessage.Content().ReadAs(ErrorBodyContent);
    //         //Error(RequestErr, Response.HttpStatusCode(), ErrorBodyContent);
    //         ResponseText := Strsubstno(RequestErr, HttpResponseMessage.HttpStatusCode(), ErrorBodyContent);
    //     end;

    //     HttpResponseStatus := HttpResponseMessage.IsSuccessStatusCode();
    //     HttpResponseCode := Format(HttpResponseMessage.HttpStatusCode());
    //     HttpResponseText := ResponseText;
    //     if not HttpResponseMessage.IsSuccessStatusCode() then
    //         HttpResponseErrorText := ErrorBodyContent
    //     else
    //         HttpResponseErrorText := '';

    //     exit(ResponseText);
    // end;
}