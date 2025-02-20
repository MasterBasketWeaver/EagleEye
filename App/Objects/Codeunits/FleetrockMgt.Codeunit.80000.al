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
        if not FleetrockSetup."Use API Token" then
            exit(FleetrockSetup."API Key");
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
        FleetrockSetup.Validate("Use API Token", true);
        FleetrockSetup.Modify(true);
        exit(FleetrockSetup."API Token");
    end;


    [TryFunction]

    procedure TryToInsertStagingRecords(var OrderJsonObj: JsonObject; var ImportEntryNo: Integer)
    begin
        ImportEntryNo := InsertStagingRecords(OrderJsonObj);
    end;

    procedure InsertStagingRecords(var OrderJsonObj: JsonObject): Integer
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
        PurchHeaderStaging.Get(EntryNo);
        if PurchHeaderStaging.Processed then
            Error('Purchase Order %1 has already been processed.', PurchHeaderStaging."Entry No.");
        CreatePurchaseOrder(PurchHeaderStaging);
        exit(EntryNo);
    end;

    procedure CreatePurchaseOrder(var PurchHeaderStaging: Record "EE Purch. Header Staging")
    var
        PurchaseHeader: Record "Purchase Header";
        DocNo: Code[20];
    begin
        GetAndCheckSetup();
        FleetrockSetup.TestField("Item G/L Account No.");
        FleetrockSetup.TestField("Vendor Posting Group");
        FleetrockSetup.TestField("Tax Group Code");
        FleetrockSetup.TestField("Tax Area Code");
        if not TryToCreatePurchaseOrder(PurchHeaderStaging, DocNo) then begin
            PurchHeaderStaging."Processed Error" := true;
            PurchHeaderStaging."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(PurchHeaderStaging."Error Message"));
            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocNo) then
                PurchaseHeader.Delete(true);
        end else begin
            PurchHeaderStaging."Processed Error" := false;
            PurchHeaderStaging."Document No." := DocNo;
        end;
        PurchHeaderStaging.Modify(true);
    end;


    [TryFunction]
    local procedure TryToCreatePurchaseOrder(var PurchHeaderStaging: Record "EE Purch. Header Staging"; var DocNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CheckIfAlreadyImported(PurchHeaderStaging.id, PurchaseHeader);
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", Enum::"Purchase Document Type"::Order);
        PurchaseHeader.Validate("Posting Date", DT2Date(PurchHeaderStaging.Closed));
        PurchaseHeader.Insert(true);
        DocNo := PurchaseHeader."No.";

        PurchaseHeader.Validate("Buy-from Vendor No.", GetVendorNo(PurchHeaderStaging));
        PurchaseHeader.Validate("Payment Terms Code", GetPaymentTerms(PurchHeaderStaging));
        PurchaseHeader.Validate("EE Fleetrock ID", PurchHeaderStaging.id);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchHeaderStaging.id);
        PurchaseHeader.Modify(true);
        CreatePurchaseLines(PurchHeaderStaging, DocNo);
    end;

    [TryFunction]
    procedure TryToCheckIfAlreadyImported(ImportId: Text; var PurchaseHeader: Record "Purchase Header")
    begin
        CheckIfAlreadyImported(ImportId, PurchaseHeader);
    end;

    procedure CheckIfAlreadyImported(ImportId: Text; var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        exit(CheckIfAlreadyImported(ImportId, PurchaseHeader, true));
    end;

    procedure CheckIfAlreadyImported(ImportId: Text; var PurchaseHeader: Record "Purchase Header"; ShowAsError: Boolean): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
        PurchaseHeader.SetRange("EE Fleetrock ID", ImportId);
        if PurchaseHeader.FindFirst() then
            if ShowAsError then
                Error('Fleetrock Purchase Order %1 has already been imported as order %2.', ImportId, PurchaseHeader."No.")
            else
                exit(true);
        PurchInvHeader.SetCurrentKey("EE Fleetrock ID");
        PurchInvHeader.SetRange("EE Fleetrock ID", ImportId);
        if PurchInvHeader.FindFirst() then
            if ShowAsError then
                Error('Fleetrock Purchase Order %1 has already been imported as order %2, and posted as invoice %3.', ImportId, PurchInvHeader."Order No.", PurchInvHeader."No.")
            else
                exit(true);
        exit(false);
    end;

    local procedure CreatePurchaseLines(var PurchHeaderStaging: Record "EE Purch. Header Staging"; DocNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchLineStaging: Record "EE Purch. Line Staging";
        LineNo: Integer;
        Taxable: Boolean;
    begin
        PurchLineStaging.SetRange(id, PurchHeaderStaging.id);
        PurchLineStaging.SetRange("Header Entry No.", PurchHeaderStaging."Entry No.");
        if not PurchLineStaging.FindSet() then
            exit;
        Taxable := PurchHeaderStaging.tax_total <> 0;
        repeat
            LineNo += 10000;
            PurchaseLine.Init();
            PurchaseLine.Validate("Document Type", Enum::"Purchase Document Type"::Order);
            PurchaseLine.Validate("Document No.", DocNo);
            PurchaseLine.Validate("Line No.", LineNo);
            PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
            PurchaseLine.Validate("No.", FleetRockSetup."Item G/L Account No.");
            PurchaseLine.Validate(Quantity, PurchLineStaging.part_quantity);
            PurchaseLine.Validate("Unit Cost", PurchLineStaging.unit_price);
            PurchaseLine.Validate("Direct Unit Cost", PurchLineStaging.unit_price);
            PurchaseLine.Description := CopyStr(PurchLineStaging.part_description, 1, MaxStrLen(PurchaseLine.Description));
            PurchaseLine.Validate("Tax Group Code", FleetrockSetup."Tax Group Code");
            PurchaseLine.Insert(true);
        until PurchLineStaging.Next() = 0;
    end;



    local procedure GetVendorNo(var PurchHeaderStaging: Record "EE Purch. Header Staging"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        if PurchHeaderStaging.supplier_name = '' then
            Error('Supplier Name must be specified.');
        Vendor.SetRange("EE Source Type", Vendor."EE Source Type"::Fleetrock);
        Vendor.SetRange("EE Source No.", PurchHeaderStaging.supplier_name);
        if Vendor.FindFirst() then
            exit(Vendor."No.");
        Vendor.Init();
        Vendor.Insert(true);
        Vendor.Validate(Name, PurchHeaderStaging.supplier_name);
        Vendor.Validate("EE Source Type", Vendor."EE Source Type"::Fleetrock);
        Vendor.Validate("EE Source No.", PurchHeaderStaging.supplier_name);
        Vendor.Validate("Vendor Posting Group", FleetrockSetup."Vendor Posting Group");
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetPaymentTerms(var PurchHeaderStaging: Record "EE Purch. Header Staging"): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        DateForm: DateFormula;
    begin
        if PurchHeaderStaging.payment_term_days = 0 then
            Error('Payment Term Days must be specified.');
        PaymentTerms.SetFilter(Code, StrSubstNo('*%1*', PurchHeaderStaging.payment_term_days));
        if PaymentTerms.FindFirst() then
            exit(PaymentTerms.Code);
        PaymentTerms.SetRange(Code);
        PaymentTerms.SetFilter(Description, StrSubstNo('*%1*', PurchHeaderStaging.payment_term_days));
        if PaymentTerms.FindFirst() then
            exit(PaymentTerms.Code);
        PaymentTerms.Init();
        PaymentTerms.Validate(Code, StrSubstNo('%1D', PurchHeaderStaging.payment_term_days));
        PaymentTerms.Validate(Description, StrSubstNo('%1 days', PurchHeaderStaging.payment_term_days));
        Evaluate(DateForm, StrSubstNo('<%1D>', PurchHeaderStaging.payment_term_days));
        PaymentTerms.Validate("Due Date Calculation", DateForm);
        PaymentTerms.Insert(true);
        exit(PaymentTerms.Code);
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


    procedure GetSuppliers(): JsonArray
    var
        APIToken: Text;
    begin
        APIToken := CheckToGetAPIToken();
        exit(GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetSuppliers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, APIToken), 'suppliers'));
    end;


    [TryFunction]
    procedure TryToGetPurchaseOrders(Status: Enum "EE Purch. Order Status"; var PurchOrdersJsonArray: JsonArray)
    begin
        PurchOrdersJsonArray := GetPurchaseOrders(Status);
    end;

    procedure GetPurchaseOrders(Status: Enum "EE Purch. Order Status"): JsonArray
    var
        APIToken: Text;
    begin
        APIToken := CheckToGetAPIToken();
        exit(GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetPO?username=%2&status=%3&token=%4', FleetrockSetup."Integration URL", FleetrockSetup.Username, Status, APIToken), 'purchase_orders'));
    end;



    [TryFunction]
    procedure TryToGetClosedPurchaseOrders(StartDateTime: DateTime; var PurchOrdersJsonArray: JsonArray)
    begin
        PurchOrdersJsonArray := GetClosedPurchaseOrders(StartDateTime);
    end;

    procedure GetClosedPurchaseOrders(StartDateTime: DateTime): JsonArray
    var
        APIToken, URL : Text;
        EndDateTime: DateTime;
    begin
        APIToken := CheckToGetAPIToken();
        if StartDateTime = 0DT then begin
            FleetrockSetup.TestField("Earliest Import DateTime");
            StartDateTime := FleetrockSetup."Earliest Import DateTime";
        end else
            if FleetrockSetup."Earliest Import DateTime" > StartDateTime then
                StartDateTime := FleetrockSetup."Earliest Import DateTime";
        URL := '%1/API/GetPO?username=%2&event=closed&token=%3&start=%4&end=%5';
        if DT2Date(StartDateTime) < Today() then
            EndDateTime := CreateDateTime(Today(), DT2Time(StartDateTime))
        else
            EndDateTime := CreateDateTime(CalcDate('<+1D>', DT2Date(StartDateTime)), DT2Time(StartDateTime));
        URL := StrSubstNo(URL, FleetrockSetup."Integration URL", FleetrockSetup.Username, APIToken, Format(StartDateTime, 0, 9), Format(EndDateTime, 0, 9));
        exit(GetResponseAsJsonArray(FleetrockSetup, URL, 'purchase_orders'));
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
            if ResponseText.Contains('"result":"error"') then
                Error(ResponseText);
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
            if ResponseText.Contains('"result":"error"') then
                Error(ResponseText);
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


    procedure InsertImportEntry(EntryNo: Integer; Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; ErrorMsg: Text)
    var
        ImportEntry: Record "EE Fleetrock Import Entry";
    begin
        ImportEntry.Init();
        ImportEntry."Entry No." := EntryNo;
        ImportEntry.Type := Type;
        ImportEntry.Success := Success;
        ImportEntry."Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(ImportEntry."Error Message"));
        ImportEntry."Import Entry No." := ImportEntryNo;
        ImportEntry.Insert(true);
    end;


    var
        FleetrockSetup: Record "EE Fleetrock Setup";

}