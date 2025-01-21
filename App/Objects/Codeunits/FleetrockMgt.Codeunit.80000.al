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


    local procedure GetAndCheckSetup()
    begin
        FleetrockSetup.Get();
        FleetrockSetup.TestField("Integration URL");
        FleetrockSetup.TestField("Username");
        FleetrockSetup.TestField("API Key");
    end;


    procedure CheckToGetAPIToken(): Text
    var
        ResponseText: Text;
    begin
        GetAndCheckSetup();
        if (FleetrockSetup."API Token" <> '') and (FleetrockSetup."API Token Expiry Date" >= Today()) then
            exit(FleetrockSetup."API Token");
        exit(CheckToGetAPIToken(FleetrockSetup));
    end;

    procedure CheckToGetAPIToken(var FleetrockSetup: Record "EE Fleetrock Setup"): Text
    var
        JsonTkn: JsonToken;
    begin
        JsonTkn := GetResponseAsJsonToken(FleetrockSetup, StrSubstNo('%1/API/GetToken?username=%2&key=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, FleetrockSetup."API Key"), 'token');
        JsonTkn.WriteTo(FleetrockSetup."API Token");
        FleetrockSetup.Validate("API Token", FleetrockSetup."API Token".Replace('"', ''));
        FleetrockSetup.Validate("API Token Expiry Date", CalcDate('<+180D>', Today()));
        FleetrockSetup.Modify(true);
        exit(FleetrockSetup."API Token");
    end;





    procedure GetUnits()
    var
        APIToken: Text;
        JsonArry: JsonArray;
        T: JsonToken;
        UnitJsonObj: JsonObject;
    begin
        APIToken := CheckToGetAPIToken();
        JsonArry := GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetUnits?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, APIToken), 'units');
        foreach T in JsonArry do begin
            UnitJsonObj := T.AsObject();
        end;
    end;


    local procedure GetResponseAsJsonToken(var FleetrockSetup: Record "EE Fleetrock Setup"; URL: Text; TokenName: Text): Variant
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
            Error('Token %1 not found in response:\%2', TokenName, ResponseText);
        end;
        exit(JsonTkn);
    end;

    local procedure GetResponseAsJsonArray(var FleetrockSetup: Record "EE Fleetrock Setup"; URL: Text; TokenName: Text): Variant
    var
        ResponseText: Text;
        JsonObj: JsonObject;
        JsonArry: JsonArray;
        JsonTkn: JsonToken;
        Result: Boolean;
    begin
        if not SendRequest('GET', URL, ResponseText) then
            Error(ResponseText);
        JsonObj.ReadFrom(ResponseText);
        if not JsonObj.Get(TokenName, JsonTkn) then begin
            JsonObj.WriteTo(ResponseText);
            Error('Token %1 not found in response:\%2', TokenName, ResponseText);
        end;
        JsonArry := JsonTkn.AsArray();
        exit(JsonArry);
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


    var
        FleetrockSetup: Record "EE Fleetrock Setup";

}