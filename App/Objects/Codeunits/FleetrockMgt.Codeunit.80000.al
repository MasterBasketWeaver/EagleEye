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




    procedure CreatePurchaseOrder(var OrderJsonObj: JsonObject)
    var
        PurchHeaderStaging: Record "EE Purch. Header Staging";
        EntryNo: Integer;
    begin
        if PurchHeaderStaging.FindLast() then
            EntryNo := PurchHeaderStaging."Entry No.";
        EntryNo += 1;
        if not TryToInsertPurchStaging(OrderJsonObj, EntryNo) then begin
            if not PurchHeaderStaging.Get(EntryNo) then begin
                PurchHeaderStaging.Init();
                PurchHeaderStaging."Entry No." := EntryNo;
                PurchHeaderStaging.Insert(true);
            end;
            PurchHeaderStaging."Insert Error" := true;
            PurchHeaderStaging."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(PurchHeaderStaging."Error Message"));
            PurchHeaderStaging.Modify(true);
        end;
    end;


    [TryFunction]
    local procedure TryToInsertPurchStaging(var OrderJsonObj: JsonObject; EntryNo: Integer)
    var
        PurchHeaderStaging: Record "EE Purch. Header Staging";
        PurchLineStaging: Record "EE Purch. Line Staging";
        Lines: JsonArray;
        LineJsonObj: JsonObject;
        T: JsonToken;
    begin
        PurchHeaderStaging.Init();
        PurchHeaderStaging."Entry No." := EntryNo;
        PurchHeaderStaging.id := GetJsonValueAsText(OrderJsonObj, 'id');
        PurchHeaderStaging.supplier_name := GetJsonValueAsText(OrderJsonObj, 'supplier_name');
        PurchHeaderStaging.supplier_custom_id := GetJsonValueAsText(OrderJsonObj, 'supplier_custom_id');
        PurchHeaderStaging.recipient_name := GetJsonValueAsText(OrderJsonObj, 'recipient_name');
        PurchHeaderStaging.tag := GetJsonValueAsText(OrderJsonObj, 'tag');
        PurchHeaderStaging.status := GetJsonValueAsText(OrderJsonObj, 'status');
        PurchHeaderStaging.date_created := GetJsonValueAsText(OrderJsonObj, 'date_created');
        PurchHeaderStaging.date_opened := GetJsonValueAsText(OrderJsonObj, 'date_opened');
        PurchHeaderStaging.date_received := GetJsonValueAsText(OrderJsonObj, 'date_received');
        PurchHeaderStaging.date_closed := GetJsonValueAsText(OrderJsonObj, 'date_closed');
        PurchHeaderStaging.payment_term_days := GetJsonValueAsDecimal(OrderJsonObj, 'payment_term_days');
        PurchHeaderStaging.invoice_number := GetJsonValueAsText(OrderJsonObj, 'invoice_number');
        PurchHeaderStaging.subtotal := GetJsonValueAsDecimal(OrderJsonObj, 'subtotal');
        PurchHeaderStaging.tax_total := GetJsonValueAsDecimal(OrderJsonObj, 'tax_total');
        PurchHeaderStaging.shipping_total := GetJsonValueAsDecimal(OrderJsonObj, 'shipping_total');
        PurchHeaderStaging.other_total := GetJsonValueAsDecimal(OrderJsonObj, 'other_total');
        PurchHeaderStaging.grand_total := GetJsonValueAsDecimal(OrderJsonObj, 'grand_total');
        PurchHeaderStaging.FormatDateValues();
        PurchHeaderStaging.Insert(true);


        if PurchLineStaging.FindLast() then
            EntryNo := PurchLineStaging."Entry No."
        else
            EntryNo := 0;

        OrderJsonObj.Get('line_items', T);
        Lines := T.AsArray();
        foreach T in Lines do begin
            EntryNo += 1;
            LineJsonObj := T.AsObject();
            PurchLineStaging.Init();
            PurchLineStaging."Entry No." := EntryNo;
            PurchLineStaging."Header Entry No." := PurchHeaderStaging."Entry No.";
            PurchLineStaging.id := PurchHeaderStaging.id;
            PurchLineStaging.part_id := GetJsonValueAsText(LineJsonObj, 'part_id');
            PurchLineStaging.part_number := GetJsonValueAsText(LineJsonObj, 'part_number');
            PurchLineStaging.part_description := GetJsonValueAsText(LineJsonObj, 'part_description');
            PurchLineStaging.part_system_code := GetJsonValueAsText(LineJsonObj, 'part_system_code');
            PurchLineStaging.part_type := GetJsonValueAsText(LineJsonObj, 'part_type');
            PurchLineStaging.tag := GetJsonValueAsText(LineJsonObj, 'tag');
            PurchLineStaging.part_quantity := GetJsonValueAsDecimal(LineJsonObj, 'part_quantity');
            PurchLineStaging.unit_price := GetJsonValueAsDecimal(LineJsonObj, 'unit_price');
            PurchLineStaging.line_total := GetJsonValueAsDecimal(LineJsonObj, 'line_total');
            PurchLineStaging.date_added := GetJsonValueAsText(LineJsonObj, 'date_added');
            PurchLineStaging.FormatDateValues();
            PurchLineStaging.Insert(true);
        end;

    end;


    local procedure GetJsonValueAsText(var JsonObj: JsonObject; KeyName: Text): Text
    var
        T: JsonToken;
    begin
        JsonObj.Get(KeyName, T);
        exit(T.AsValue().AsText());
    end;

    local procedure GetJsonValueAsDecimal(var JsonObj: JsonObject; KeyName: Text): Decimal
    var
        T: JsonToken;
    begin
        JsonObj.Get(KeyName, T);
        exit(T.AsValue().AsDecimal());
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


    procedure GetSuppliers()
    var
        APIToken: Text;
        JsonArry: JsonArray;
        T: JsonToken;
        UnitJsonObj: JsonObject;
    begin
        APIToken := CheckToGetAPIToken();
        JsonArry := GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetSuppliers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, APIToken), 'suppliers');

        Message(Format(JsonArry));

        // foreach T in JsonArry do begin
        //     UnitJsonObj := T.AsObject();
        // end;
    end;

    procedure GetPurchaseOrders(Status: Enum "EE Purch. Order Status"): JsonArray
    var
        APIToken: Text;
    begin
        APIToken := CheckToGetAPIToken();
        exit(GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetPO?username=%2&status=%3&token=%4', FleetrockSetup."Integration URL", FleetrockSetup.Username, Status, APIToken), 'purchase_orders'));
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