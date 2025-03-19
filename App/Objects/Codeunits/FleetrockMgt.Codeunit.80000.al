codeunit 80000 "EE Fleetrock Mgt."
{
    Permissions = tabledata "EE Fleetrock Setup" = rimd,
    tabledata "EE Purch. Header Staging" = rimd,
    tabledata "EE Purch. Line Staging" = rimd,
    tabledata "EE Import/Export Entry" = rimd,
    tabledata "EE Sales Header Staging" = rimd,
    tabledata "EE Task Line Staging" = rimd,
    tabledata "EE Part Line Staging" = rimd,
    tabledata "Purchase Header" = rimd,
    tabledata "Purchase Line" = rimd,
    tabledata "Sales Header" = rimd,
    tabledata "Sales Line" = rimd,
    tabledata "Vendor" = rimd,
    tabledata "Payment Terms" = rimd,
    tabledata "G/L Account" = rimd,
    tabledata "Purch. Inv. Header" = r,
    tabledata "Purch. Inv. Line" = r,
    tabledata "Sales Invoice Header" = r,
    tabledata "Sales Invoice Line" = r;


    // [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterInsertEvent, '', false, false)]
    // local procedure GLAccountOnAfterInsert(var Rec: Record "G/L Account")
    // begin
    //     SyncGLToFleetRock(Rec, false);
    // end;

    // [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterModifyEvent, '', false, false)]
    // local procedure GLAccountOnAfterModify(var Rec: Record "G/L Account")
    // begin
    //     SyncGLToFleetRock(Rec, false);
    // end;

    // [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterDeleteEvent, '', false, false)]
    // local procedure GLAccountOnAfterDelete(var Rec: Record "G/L Account")
    // begin
    //     SyncGLToFleetRock(Rec, true);
    // end;

    // [EventSubscriber(ObjectType::Table, Database::"G/L Account", OnAfterRenameEvent, '', false, false)]
    // local procedure GLAccountOnRenameDelete(var Rec: Record "G/L Account")
    // begin
    //     SyncGLToFleetRock(Rec, false);
    // end;

    // procedure SyncGLToFleetRock(var GLAccount: Record "G/L Account"; Deleted: Boolean)
    // begin
    // end;


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
        JsonTkn := RestAPIMgt.GetResponseAsJsonToken(FleetrockSetup, StrSubstNo('%1/API/GetToken?username=%2&key=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, FleetrockSetup."API Key"), 'token');
        JsonTkn.WriteTo(FleetrockSetup."API Token");
        FleetrockSetup.Validate("API Token", FleetrockSetup."API Token".Replace('"', ''));
        FleetrockSetup.Validate("API Token Expiry Date", CalcDate('<+180D>', Today()));
        FleetrockSetup.Validate("Use API Token", true);
        FleetrockSetup.Modify(true);
        exit(FleetrockSetup."API Token");
    end;


    [TryFunction]
    procedure TryToInsertPOStagingRecords(var OrderJsonObj: JsonObject; var ImportEntryNo: Integer; CreateOrder: Boolean)
    begin
        ImportEntryNo := InsertPOStagingRecords(OrderJsonObj, CreateOrder);
    end;

    procedure InsertPOStagingRecords(var OrderJsonObj: JsonObject; CreateOrder: Boolean): Integer
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
            PurchHeaderStaging."Import Error" := true;
            PurchHeaderStaging."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(PurchHeaderStaging."Error Message"));
            PurchHeaderStaging.Modify(true);
        end;
        PurchHeaderStaging.Get(EntryNo);
        if CreateOrder then begin
            if PurchHeaderStaging.Processed then
                Error('Purchase Order %1 has already been processed.', PurchHeaderStaging."Entry No.");
            CreatePurchaseOrder(PurchHeaderStaging);
        end;
        exit(EntryNo);
    end;

    procedure CreatePurchaseOrder(var PurchHeaderStaging: Record "EE Purch. Header Staging")
    var
        PurchaseHeader: Record "Purchase Header";
        DocNo: Code[20];
    begin
        GetAndCheckSetup();
        FleetrockSetup.TestField("Purchase G/L Account No.");
        FleetrockSetup.TestField("Vendor Posting Group");
        FleetrockSetup.TestField("Tax Group Code");
        FleetrockSetup.TestField("Tax Area Code");
        FleetrockSetup.TestField("Payment Terms");
        if not TryToCreatePurchaseOrder(PurchHeaderStaging, DocNo) then begin
            PurchHeaderStaging."Processed Error" := true;
            PurchHeaderStaging."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(PurchHeaderStaging."Error Message"));
            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocNo) then
                PurchaseHeader.Delete(true);
        end else begin
            PurchHeaderStaging."Processed Error" := false;
            PurchHeaderStaging.Processed := true;
            PurchHeaderStaging."Document No." := DocNo;
        end;
        PurchHeaderStaging.Modify(true);
    end;


    [TryFunction]
    local procedure TryToCreatePurchaseOrder(var PurchHeaderStaging: Record "EE Purch. Header Staging"; var DocNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        CheckIfAlreadyImported(PurchHeaderStaging.id, PurchaseHeader);
        PurchaseHeader.Init();
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Document Type", Enum::"Purchase Document Type"::Order);
        PurchaseHeader.Validate("Posting Date", DT2Date(PurchHeaderStaging.Received));
        PurchaseHeader.Insert(true);
        DocNo := PurchaseHeader."No.";

        ClearLastError();
        if not TryToGetVendorNo(PurchHeaderStaging, VendorNo) then begin
            if Vendor.Get(VendorNo) then
                Vendor.Delete(true);
            Error(GetLastErrorText());
        end;

        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.Validate("Payment Terms Code", GetPaymentTerms(PurchHeaderStaging.payment_term_days));
        PurchaseHeader.Validate("EE Fleetrock ID", PurchHeaderStaging.id);
        if PurchHeaderStaging.invoice_number <> '' then
            PurchaseHeader.Validate("Vendor Invoice No.", PurchHeaderStaging.invoice_number)
        else
            PurchaseHeader.Validate("Vendor Invoice No.", PurchHeaderStaging.id);
        PurchaseHeader.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
        PurchaseHeader.Modify(true);
        CreatePurchaseLines(PurchHeaderStaging, DocNo);
    end;

    local procedure CreatePurchaseLines(var PurchHeaderStaging: Record "EE Purch. Header Staging"; DocNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchLineStaging: Record "EE Purch. Line Staging";
        LineNo: Integer;
    begin
        PurchLineStaging.SetRange("Header id", PurchHeaderStaging.id);
        PurchLineStaging.SetRange("Header Entry No.", PurchHeaderStaging."Entry No.");
        if not PurchLineStaging.FindSet() then
            exit;
        // Taxable := PurchHeaderStaging.tax_total <> 0;
        repeat
            LineNo += 10000;
            AddPurchaseLine(PurchaseLine, PurchLineStaging, DocNo, LineNo);
        until PurchLineStaging.Next() = 0;
    end;






    [TryFunction]
    procedure TryToCheckIfAlreadyImported(ImportId: Text; var SalesHeader: Record "Sales Header")
    begin
        CheckIfAlreadyImported(ImportId, SalesHeader);
    end;

    procedure CheckIfAlreadyImported(ImportId: Text; var SalesHeader: Record "Sales Header"): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesHeader.SetCurrentKey("EE Fleetrock ID");
        SalesHeader.SetRange("EE Fleetrock ID", ImportId);
        if SalesHeader.FindFirst() then
            Error('Fleetrock Sales Order %1 has already been imported as order %2.', ImportId, SalesHeader."No.");
        SalesInvHeader.SetCurrentKey("EE Fleetrock ID");
        SalesInvHeader.SetRange("EE Fleetrock ID", ImportId);
        if SalesInvHeader.FindFirst() then
            Error('Fleetrock Sales Order %1 has already been imported as order %2, and posted as invoice %3.', ImportId, SalesInvHeader."Order No.", SalesInvHeader."No.");
        exit(false);
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


    [TryFunction]
    local procedure TryToGetVendorNo(var PurchHeaderStaging: Record "EE Purch. Header Staging"; var VendorNo: Code[20])
    begin
        VendorNo := GetVendorNo(PurchHeaderStaging);
    end;

    local procedure GetVendorNo(var PurchHeaderStaging: Record "EE Purch. Header Staging"): Code[20]
    var
        Vendor: Record Vendor;
        VendorObj: JsonObject;
        T: JsonToken;
        PaymentTermDays: Integer;
    begin
        if PurchHeaderStaging.supplier_name = '' then
            Error('supplier_name must be specified.');
        Vendor.SetRange("EE Source Type", Vendor."EE Source Type"::Fleetrock);
        Vendor.SetRange("EE Source No.", PurchHeaderStaging.supplier_name);
        if Vendor.FindFirst() then
            exit(Vendor."No.");

        if not GetVendorDetails(PurchHeaderStaging.supplier_name, VendorObj) then begin
            // Error('Supplier %1 not found.', PurchHeaderStaging.supplier_name);
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


        Vendor.Init();
        Vendor.Insert(true);
        Vendor.Validate(Name, PurchHeaderStaging.supplier_name);
        Vendor.Validate("EE Source Type", Vendor."EE Source Type"::Fleetrock);
        Vendor.Validate("EE Source No.", PurchHeaderStaging.supplier_name);
        Vendor.Validate("Vendor Posting Group", FleetrockSetup."Vendor Posting Group");
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
        Vendor.Validate(Address, GetJsonValueAsText(VendorObj, 'street_address_1'));
        Vendor.Validate("Address 2", GetJsonValueAsText(VendorObj, 'street_address_2'));
        Vendor.Validate("City", GetJsonValueAsText(VendorObj, 'city'));
        Vendor.Validate(County, GetJsonValueAsText(VendorObj, 'state'));
        // if Vendor.County = '' then
        //     Vendor.Validate(County, GetJsonValueAsText(VendorObj, 'province'));
        Vendor."Country/Region Code" := GetJsonValueAsText(VendorObj, 'country');
        Vendor.Validate("Post Code", GetJsonValueAsText(VendorObj, 'zip_code'));
        Vendor.Validate("Phone No.", GetJsonValueAsText(VendorObj, 'phone'));
        Vendor.Validate("E-Mail", GetJsonValueAsText(VendorObj, 'email'));
        PaymentTermDays := Round(GetJsonValueAsDecimal(VendorObj, 'payment_term_days'), 1);
        if PaymentTermDays = 0 then
            Vendor.Validate("Payment Terms Code", FleetrockSetup."Payment Terms")
        else
            Vendor.Validate("Payment Terms Code", GetPaymentTerms(PaymentTermDays));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetVendorDetails(SupplierName: Text; var VendorObj: JsonObject): Boolean
    var
        VendorArray: JsonArray;
        T: JsonToken;
    begin
        CheckToGetAPIToken();
        VendorArray := RestAPIMgt.GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetSuppliers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, CheckToGetAPIToken()), 'suppliers');
        foreach T in VendorArray do begin
            VendorObj := T.AsObject();
            if VendorObj.Get('name', T) then
                if T.AsValue().AsText() = SupplierName then
                    exit(true);
        end;
    end;


    [TryFunction]
    local procedure TryToGetCustomerNo(var SalesHeaderStaging: Record "EE Sales Header Staging"; var CustomerNo: Code[20])
    begin
        CustomerNo := GetCustomerNo(SalesHeaderStaging);
    end;

    local procedure GetCustomerNo(var SalesHeaderStaging: Record "EE Sales Header Staging"): Code[20]
    var
        Customer: Record Customer;
        CustomerObj: JsonObject;
        T: JsonToken;
        SourceNo: Text;
        PaymentTermDays: Integer;
        IsSourceCompany: Boolean;
    begin
        if SalesHeaderStaging.customer_company_id <> '' then
            SourceNo := SalesHeaderStaging.customer_company_id
        else
            if SalesHeaderStaging.customer_name <> '' then begin
                SourceNo := SalesHeaderStaging.customer_name;
                IsSourceCompany := true;
            end else
                Error('customer_name or customer_company_id must be specified.');
        Customer.SetRange("EE Source Type", Customer."EE Source Type"::Fleetrock);
        Customer.SetRange("EE Source No.", SourceNo);
        if Customer.FindFirst() then
            exit(Customer."No.");

        if not GetCustomerDetails(SourceNo, IsSourceCompany, CustomerObj) then begin
            Customer.Init();
            Customer.Insert(true);
            Customer.Validate(Name, SalesHeaderStaging.customer_name);
            Customer.Validate("EE Source Type", Customer."EE Source Type"::Fleetrock);
            Customer.Validate("EE Source No.", SourceNo);
            Customer.Validate("Customer Posting Group", FleetrockSetup."Customer Posting Group");
            Customer.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
            Customer.Modify(true);
            exit(Customer."No.");
        end;

        Customer.Init();
        Customer.Insert(true);
        Customer.Validate(Name, SalesHeaderStaging.customer_name);
        Customer.Validate("EE Source Type", Customer."EE Source Type"::Fleetrock);
        Customer.Validate("EE Source No.", SourceNo);
        Customer.Validate("EE Source Search Name", GetJsonValueAsText(CustomerObj, 'username'));
        Customer.Validate(Name, StrSubstNo('%1 %2', GetJsonValueAsText(CustomerObj, 'first_name'), GetJsonValueAsText(CustomerObj, 'last_name')).Trim());
        Customer.Validate(Address, GetJsonValueAsText(CustomerObj, 'street_address'));
        Customer.Validate("City", GetJsonValueAsText(CustomerObj, 'city'));
        Customer.Validate(County, GetJsonValueAsText(CustomerObj, 'state'));
        if Customer.County = '' then
            Customer.Validate(County, GetJsonValueAsText(CustomerObj, 'province'));
        Customer."Country/Region Code" := GetJsonValueAsText(CustomerObj, 'country');
        Customer.Validate("Post Code", GetJsonValueAsText(CustomerObj, 'zip_code'));
        Customer.Validate("Customer Posting Group", FleetrockSetup."Customer Posting Group");
        Customer.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
        Customer.Validate("Payment Terms Code", FleetrockSetup."Payment Terms");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure GetCustomerDetails(SourceValue: Text; IsSourceCompany: Boolean; var CustomerObj: JsonObject): Boolean
    var
        CustomerArray: JsonArray;
        T: JsonToken;
        SourceType: Text;
    begin
        CheckToGetAPIToken();
        CustomerArray := RestAPIMgt.GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetUsers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, CheckToGetAPIToken()), 'users');
        if CustomerArray.Count() = 0 then
            exit(false);

        if IsSourceCompany then
            SourceType := 'company_name'
        else
            SourceType := 'company_id';
        foreach T in CustomerArray do begin
            CustomerObj := T.AsObject();
            if CustomerObj.Get(SourceType, T) then
                if T.AsValue().AsText() = SourceValue then
                    exit(true);
        end;
        exit(false);
    end;

    local procedure GetPaymentTerms(PaymentTermsDays: Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        DateForm: DateFormula;
    begin
        if PaymentTermsDays <= 0 then
            Error('Payment Term Days must be greater than zero: %1.', PaymentTermsDays);
        PaymentTerms.SetFilter(Code, StrSubstNo('*%1*', PaymentTermsDays));
        if PaymentTerms.FindFirst() then
            exit(PaymentTerms.Code);
        PaymentTerms.SetRange(Code);
        PaymentTerms.SetFilter(Description, StrSubstNo('*%1*', PaymentTermsDays));
        if PaymentTerms.FindFirst() then
            exit(PaymentTerms.Code);
        PaymentTerms.Init();
        PaymentTerms.Validate(Code, StrSubstNo('%1D', PaymentTermsDays));
        PaymentTerms.Validate(Description, StrSubstNo('%1 days', PaymentTermsDays));
        Evaluate(DateForm, StrSubstNo('<%1D>', PaymentTermsDays));
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
            PurchLineStaging."Header id" := PurchHeaderStaging.id;
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
            PurchLineStaging.Insert(true);
        end;
    end;


    procedure GetJsonValueAsText(var JsonObj: JsonObject; KeyName: Text): Text
    var
        T: JsonToken;
    begin
        if not JsonObj.Get(KeyName, T) then
            exit('');
        exit(T.AsValue().AsText());
    end;

    local procedure GetJsonValueAsDecimal(var JsonObj: JsonObject; KeyName: Text): Decimal
    var
        T: JsonToken;
    begin
        if not JsonObj.Get(KeyName, T) then
            exit(0);
        if Format(T.AsValue()) = '""' then
            exit(0);
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
        JsonArry := RestAPIMgt.GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetUnits?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, APIToken), 'units');
        foreach T in JsonArry do begin
            UnitJsonObj := T.AsObject();
        end;
    end;


    procedure GetSuppliers(): JsonArray
    var
        APIToken: Text;
    begin
        APIToken := CheckToGetAPIToken();
        exit(RestAPIMgt.GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetSuppliers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, APIToken), 'suppliers'));
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
        exit(RestAPIMgt.GetResponseAsJsonArray(FleetrockSetup, StrSubstNo('%1/API/GetPO?username=%2&status=%3&token=%4', FleetrockSetup."Integration URL", FleetrockSetup.Username, Status, APIToken), 'purchase_orders'));
    end;



    [TryFunction]
    procedure TryToGetPurchaseOrders(StartDateTime: DateTime; var PurchOrdersJsonArray: JsonArray; var URL: Text; EventType: Enum "EE Event Type")
    begin
        PurchOrdersJsonArray := GetPurchaseOrders(StartDateTime, URL, EventType);
    end;

    // [TryFunction]
    // procedure TryToGetReceivedPurchaseOrders(StartDateTime: DateTime; var PurchOrdersJsonArray: JsonArray; var URL: Text)
    // begin
    //     PurchOrdersJsonArray := GetPurchaseOrders(StartDateTime, URL, Enum::"EE Event Type"::Received);
    // end;

    procedure GetPurchaseOrders(StartDateTime: DateTime; var URL: Text; EventType: Enum "EE Event Type"): JsonArray
    var
        APIToken: Text;
        EndDateTime: DateTime;
    begin
        GetEventParameters(APIToken, StartDateTime, EndDateTime);
        URL := StrSubstNo('%1/API/GetPO?username=%2&event=%3&token=%4&start=%5&end=%6', FleetrockSetup."Integration URL",
            FleetrockSetup.Username, EventType, APIToken, Format(StartDateTime, 0, 9), Format(EndDateTime, 0, 9));
        exit(RestAPIMgt.GetResponseAsJsonArray(FleetrockSetup, URL, 'purchase_orders'));
    end;








    [TryFunction]
    procedure TryToGetRepairOrders(StartDateTime: DateTime; Status: Enum "EE Repair Order Status"; var RepairOrdersJsonArray: JsonArray; var URL: Text)
    begin
        RepairOrdersJsonArray := GetRepairOrders(StartDateTime, Status, URL);
    end;

    procedure GetRepairOrders(StartDateTime: DateTime; Status: Enum "EE Repair Order Status"; var URL: Text): JsonArray
    var
        APIToken: Text;
        EndDateTime: DateTime;
    begin
        GetEventParameters(APIToken, StartDateTime, EndDateTime);
        URL := StrSubstNo('%1/API/GetRO?username=%2&event=%3&token=%4&start=%5&end=%6', FleetrockSetup."Integration URL",
            FleetrockSetup.Username, Status, APIToken, Format(StartDateTime, 0, 9), Format(EndDateTime, 0, 9));
        exit(RestAPIMgt.GetResponseAsJsonArray(FleetrockSetup, URL, 'repair_orders'));
    end;



    local procedure GetEventParameters(var APIToken: Text; var StartDateTime: DateTime; var EndDateTime: DateTime)
    begin
        APIToken := CheckToGetAPIToken();
        if StartDateTime = 0DT then begin
            FleetrockSetup.TestField("Earliest Import DateTime");
            StartDateTime := FleetrockSetup."Earliest Import DateTime";
        end else
            if FleetrockSetup."Earliest Import DateTime" > StartDateTime then
                StartDateTime := FleetrockSetup."Earliest Import DateTime";
        EndDateTime := CurrentDateTime();
    end;



    [TryFunction]
    procedure TryToInsertROStagingRecords(var OrderJsonObj: JsonObject; var ImportEntryNo: Integer; CreateInvoice: Boolean)
    begin
        ImportEntryNo := InsertROStagingRecords(OrderJsonObj, CreateInvoice);
    end;

    procedure InsertROStagingRecords(var OrderJsonObj: JsonObject; CreateInvoice: Boolean): Integer
    var
        SalesHeaderStaging: Record "EE Sales Header Staging";
        EntryNo: Integer;
    begin
        if SalesHeaderStaging.FindLast() then
            EntryNo := SalesHeaderStaging."Entry No.";
        EntryNo += 1;
        if not TryToInsertSalesStaging(OrderJsonObj, EntryNo) then begin
            if not SalesHeaderStaging.Get(EntryNo) then begin
                SalesHeaderStaging.Init();
                SalesHeaderStaging."Entry No." := EntryNo;
                SalesHeaderStaging.Insert(true);
            end;
            SalesHeaderStaging."Import Error" := true;
            SalesHeaderStaging."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(SalesHeaderStaging."Error Message"));
            SalesHeaderStaging.Modify(true);
        end;
        SalesHeaderStaging.Get(EntryNo);
        if CreateInvoice then begin
            if SalesHeaderStaging.Processed then
                Error('Repair Order %1 has already been processed.', SalesHeaderStaging."Entry No.");
            CreateSalesOrder(SalesHeaderStaging);
        end;
        exit(EntryNo);
    end;

    [TryFunction]
    local procedure TryToInsertSalesStaging(var OrderJsonObj: JsonObject; EntryNo: Integer)
    var
        SalesHeaderStaging: Record "EE Sales Header Staging";
        TaskLineStaging: Record "EE Task Line Staging";
        PartLineStaging: Record "EE Part Line Staging";

        TaskLines, PartLines : JsonArray;
        TaskLineJsonObj, PartLineJsonObj : JsonObject;
        T: JsonToken;
        RecVar: Variant;
        PartEntryNo: Integer;
    begin
        SalesHeaderStaging.Init();
        SalesHeaderStaging."Entry No." := EntryNo;
        RecVar := SalesHeaderStaging;

        PopulateStagingTable(RecVar, OrderJsonObj, Database::"EE Sales Header Staging", SalesHeaderStaging.FieldNo(id));
        SalesHeaderStaging := RecVar;
        if FleetrockSetup."Internal Customer Name" <> '' then
            SalesHeaderStaging."Internal Customer" := SalesHeaderStaging.customer_name = FleetrockSetup."Internal Customer Name";
        SalesHeaderStaging.Insert(true);

        if not OrderJsonObj.Get('tasks', T) then
            exit;
        TaskLines := T.AsArray();
        if TaskLines.Count() = 0 then
            exit;
        if TaskLineStaging.FindLast() then
            EntryNo := TaskLineStaging."Entry No."
        else
            EntryNo := 0;
        if PartLineStaging.FindLast() then
            PartEntryNo := PartLineStaging."Entry No.";
        foreach T in TaskLines do begin
            EntryNo += 1;
            TaskLineJsonObj := T.AsObject();
            TaskLineStaging.Init();
            TaskLineStaging."Entry No." := EntryNo;
            TaskLineStaging."Header Entry No." := SalesHeaderStaging."Entry No.";
            TaskLineStaging."Header Id" := SalesHeaderStaging.id;
            RecVar := TaskLineStaging;
            PopulateStagingTable(RecVar, TaskLineJsonObj, Database::"EE Task Line Staging", TaskLineStaging.FieldNo("task_id"));
            TaskLineStaging := RecVar;
            TaskLineStaging.Insert(true);
            if TaskLineJsonObj.Get('parts', T) then begin
                PartLines := T.AsArray();
                foreach T in PartLines do begin
                    PartEntryNo += 1;
                    PartLineJsonObj := T.AsObject();
                    partLineStaging.Init();
                    PartLineStaging."Entry No." := PartEntryNo;
                    PartLineStaging."Header Entry No." := SalesHeaderStaging."Entry No.";
                    PartLineStaging."Header Id" := SalesHeaderStaging.id;
                    PartLineStaging."Task Entry No." := TaskLineStaging."Entry No.";
                    PartLineStaging."Task Id" := TaskLineStaging.task_id;
                    RecVar := PartLineStaging;
                    PopulateStagingTable(RecVar, PartLineJsonObj, Database::"EE Part Line Staging", PartLineStaging.FieldNo("task_part_id"));
                    PartLineStaging := RecVar;
                    PartLineStaging.Insert(true);
                end;
            end;
        end;
    end;



    procedure CreateSalesOrder(var SalesHeaderStaging: Record "EE Sales Header Staging")
    var
        SalesaseHeader: Record "Sales Header";
        DocNo: Code[20];
    begin
        GetAndCheckSetup();
        FleetrockSetup.TestField("External Labor G/L Account No.");
        FleetrockSetup.TestField("External Parts G/L Account No.");
        if FleetrockSetup."Internal Customer Name" <> '' then begin
            FleetrockSetup.TestField("Internal Labor G/L Account No.");
            FleetrockSetup.TestField("Internal Parts G/L Account No.");
        end;
        FleetrockSetup.TestField("Customer Posting Group");
        FleetrockSetup.TestField("Tax Group Code");
        FleetrockSetup.TestField("Tax Area Code");
        FleetrockSetup.TestField("Payment Terms");
        if not TryToCreateSalesOrder(SalesHeaderStaging, DocNo) then begin
            SalesHeaderStaging."Processed Error" := true;
            SalesHeaderStaging."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(SalesHeaderStaging."Error Message"));
            if SalesaseHeader.Get(SalesaseHeader."Document Type"::Order, DocNo) then
                SalesaseHeader.Delete(true);
        end else begin
            SalesHeaderStaging."Processed Error" := false;
            SalesHeaderStaging.Processed := true;
            SalesHeaderStaging."Document No." := DocNo;
        end;
        SalesHeaderStaging.Modify(true);
    end;


    [TryFunction]
    local procedure TryToCreateSalesOrder(var SalesHeaderStaging: Record "EE Sales Header Staging"; var DocNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        CheckIfAlreadyImported(SalesHeaderStaging.id, SalesHeader);
        SalesHeader.Init();
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.SetHideCreditCheckDialogue(true);
        SalesHeader.Validate("Document Type", Enum::"Sales Document Type"::Invoice);
        SalesHeader.Validate("Posting Date", DT2Date(SalesHeaderStaging."Expected Finish At"));
        SalesHeader.Insert(true);
        DocNo := SalesHeader."No.";

        ClearLastError();
        if not TryToGetCustomerNo(SalesHeaderStaging, CustomerNo) then begin
            if Customer.Get(CustomerNo) then
                Customer.Delete(true);
            Error(GetLastErrorText());
        end;
        Customer.Get(CustomerNo);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        if Customer."Payment Terms Code" = '' then
            SalesHeader.Validate("Payment Terms Code", FleetrockSetup."Payment Terms")
        else
            SalesHeader.Validate("Payment Terms Code", Customer."Payment Terms Code");
        SalesHeader.Validate("EE Fleetrock ID", SalesHeaderStaging.id);
        if SalesHeaderStaging.po_number <> '' then
            SalesHeader.Validate("External Document No.", CopyStr(SalesHeaderStaging.po_number, 1, MaxStrLen(SalesHeader."External Document No.")))
        else
            SalesHeader.Validate("External Document No.", SalesHeaderStaging.id);
        SalesHeader.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
        SalesHeader.Modify(true);
        CreateSalesLines(SalesHeaderStaging, DocNo);
    end;

    local procedure CreateSalesLines(var SalesHeaderStaging: Record "EE Sales Header Staging"; DocNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        TaskLineStaging: Record "EE Task Line Staging";
        PartLineStaging: Record "EE Part Line Staging";
        LineNo: Integer;
        Taxable: Boolean;
    begin
        TaskLineStaging.SetCurrentKey("Header Id", "Header Entry No.");
        TaskLineStaging.SetRange("Header Id", SalesHeaderStaging.id);
        TaskLineStaging.SetRange("Header Entry No.", SalesHeaderStaging."Entry No.");
        TaskLineStaging.SetAutoCalcFields("Part Lines");
        if not TaskLineStaging.FindSet() then
            exit;
        Taxable := SalesHeaderStaging.tax_total <> 0;
        PartLineStaging.SetCurrentKey("Header Id", "Header Entry No.", "Task Entry No.", "Task Id");
        PartLineStaging.SetRange("Header Id", SalesHeaderStaging.id);
        PartLineStaging.SetRange("Header Entry No.", SalesHeaderStaging."Entry No.");
        repeat
            LineNo += 10000;
            AddTaskSalesLine(SalesLine, TaskLineStaging, DocNo, LineNo, SalesHeaderStaging."Internal Customer");
            if TaskLineStaging."Part Lines" > 0 then begin
                PartLineStaging.SetRange("Task Entry No.", TaskLineStaging."Entry No.");
                PartLineStaging.SetRange("Task Id", TaskLineStaging.task_id);
                if PartLineStaging.FindSet() then
                    repeat
                        LineNo += 10000;
                        AddPartSalesLine(SalesLine, PartLineStaging, DocNo, LineNo, SalesHeaderStaging."Internal Customer");
                    until PartLineStaging.Next() = 0;
            end;
        until TaskLineStaging.Next() = 0;
    end;

    local procedure AddTaskSalesLine(var SalesLine: Record "Sales Line"; var TaskLineStaging: Record "EE Task Line Staging"; DocNo: Code[20]; LineNo: Integer; Internal: Boolean)
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", Enum::"Sales Document Type"::Invoice);
        SalesLine.Validate("Document No.", DocNo);
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        if Internal then
            SalesLine.Validate("No.", FleetRockSetup."Internal Labor G/L Account No.")
        else
            SalesLine.Validate("No.", FleetRockSetup."External Labor G/L Account No.");
        SalesLine.Validate(Quantity, TaskLineStaging.labor_hours);
        SalesLine.Validate("Unit Price", TaskLineStaging.labor_hourly_rate);
        SalesLine.Description := CopyStr(TaskLineStaging.labor_system_code, 1, MaxStrLen(SalesLine.Description));
        SalesLine.Validate("Tax Group Code", FleetrockSetup."Tax Group Code");
        SalesLine.Validate("EE Task/Part Id", TaskLineStaging.task_id);
        SalesLine.Insert(true);
    end;

    local procedure AddPartSalesLine(var SalesLine: Record "Sales Line"; var PartLineStaging: Record "EE Part Line Staging"; DocNo: Code[20]; LineNo: Integer; Internal: Boolean)
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", Enum::"Sales Document Type"::Invoice);
        SalesLine.Validate("Document No.", DocNo);
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        if Internal then
            SalesLine.Validate("No.", FleetRockSetup."Internal Parts G/L Account No.")
        else
            SalesLine.Validate("No.", FleetRockSetup."External Parts G/L Account No.");
        SalesLine.Validate(Quantity, PartLineStaging.part_quantity);
        SalesLine.Validate("Unit Price", PartLineStaging.part_price);
        SalesLine.Description := CopyStr(PartLineStaging.part_description, 1, MaxStrLen(SalesLine.Description));
        SalesLine.Validate("Tax Group Code", FleetrockSetup."Tax Group Code");
        SalesLine.Validate("EE Task/Part Id", PartLineStaging.part_id);
        SalesLine.Insert(true);
    end;



    [TryFunction]
    procedure TryToUpdateRepairOrder(var SalesHeaderStaging: Record "EE Sales Header Staging"; DocNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaskLineStaging: Record "EE Task Line Staging";
        PartLineStaging: Record "EE Part Line Staging";
        LineNo, DescrLength : Integer;
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, DocNo);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", DT2Date(SalesHeaderStaging."Invoiced At"));
        SalesHeader.Modify(true);
        if SalesHeaderStaging."Document No." <> SalesHeader."No." then begin
            SalesHeaderStaging.Validate("Document No.", SalesHeader."No.");
            SalesHeaderStaging.Modify(true);
        end;
        TaskLineStaging.SetCurrentKey("Header Id", "Header Entry No.");
        TaskLineStaging.SetRange("Header Id", SalesHeaderStaging.id);
        TaskLineStaging.SetRange("Header Entry No.", SalesHeaderStaging."Entry No.");
        TaskLineStaging.SetAutoCalcFields("Part Lines");
        if not TaskLineStaging.FindSet() then
            exit;
        PartLineStaging.SetCurrentKey("Header Id", "Header Entry No.", "Task Entry No.", "Task Id");
        PartLineStaging.SetRange("Header Id", SalesHeaderStaging.id);
        PartLineStaging.SetRange("Header Entry No.", SalesHeaderStaging."Entry No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No.";
        DescrLength := MaxStrLen(SalesLine.Description);
        repeat
            SalesLine.SetRange("EE Task/Part Id", TaskLineStaging.task_id);
            if not SalesLine.FindFirst() then begin
                LineNo += 10000;
                AddTaskSalesLine(SalesLine, TaskLineStaging, SalesHeader."No.", LineNo, SalesHeaderStaging."Internal Customer");
            end else begin
                SalesLine.Validate(Quantity, TaskLineStaging.labor_hours);
                SalesLine.Validate("Unit Price", TaskLineStaging.labor_hourly_rate);
                SalesLine.Description := CopyStr(TaskLineStaging.labor_system_code, 1, DescrLength);
                SalesLine.Modify(true);
            end;
            if TaskLineStaging."Part Lines" > 0 then begin
                PartLineStaging.SetRange("Task Entry No.", TaskLineStaging."Entry No.");
                PartLineStaging.SetRange("Task Id", TaskLineStaging.task_id);
                if PartLineStaging.FindSet() then
                    repeat
                        SalesLine.SetRange("EE Task/Part Id", PartLineStaging.part_id);
                        if not SalesLine.FindFirst() then begin
                            LineNo += 10000;
                            AddPartSalesLine(SalesLine, PartLineStaging, SalesHeader."No.", LineNo, SalesHeaderStaging."Internal Customer");
                        end else begin
                            SalesLine.Validate(Quantity, PartLineStaging.part_quantity);
                            SalesLine.Validate("Unit Price", PartLineStaging.part_price);
                            SalesLine.Description := CopyStr(PartLineStaging.part_description, 1, DescrLength);
                            SalesLine.Modify(true);
                        end;
                    until PartLineStaging.Next() = 0;
            end;
        until TaskLineStaging.Next() = 0;
    end;

    [TryFunction]
    procedure TryToUpdatePurchaseOrder(var PurchaseHeaderStaging: Record "EE Purch. Header Staging"; DocNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineStaging: Record "EE Purch. Line Staging";
        LineNo: Integer;
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocNo);
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", DT2Date(PurchaseHeaderStaging.Closed));
        PurchaseHeader.Modify(true);
        PurchaseHeaderStaging.Processed := true;
        PurchaseHeaderStaging.Modify(true);
        if PurchaseHeaderStaging."Document No." <> PurchaseHeader."No." then begin
            PurchaseHeaderStaging.Validate("Document No.", PurchaseHeader."No.");
            PurchaseHeaderStaging.Modify(true);
        end;
        PurchLineStaging.SetCurrentKey("Header Id", "Header Entry No.");
        PurchLineStaging.SetRange("Header Id", PurchaseHeaderStaging.id);
        PurchLineStaging.SetRange("Header Entry No.", PurchaseHeaderStaging."Entry No.");
        if not PurchLineStaging.FindSet() then
            exit;

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindLast() then
            LineNo := PurchaseLine."Line No.";
        repeat
            PurchaseLine.SetRange("EE Part Id", PurchLineStaging.part_id);
            if not PurchaseLine.FindFirst() then begin
                LineNo += 10000;
                AddPurchaseLine(PurchaseLine, PurchLineStaging, PurchaseHeader."No.", LineNo);
            end else begin
                PurchaseLine.Validate(Quantity, PurchLineStaging.part_quantity);
                PurchaseLine.Validate("Unit Cost", PurchLineStaging.unit_price);
                PurchaseLine.Validate("Direct Unit Cost", PurchLineStaging.unit_price);
                PurchaseLine.Description := CopyStr(PurchLineStaging.part_description, 1, MaxStrLen(PurchaseLine.Description));
                PurchaseLine.Modify(true);
            end;
        until PurchLineStaging.Next() = 0;
    end;

    local procedure AddPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchLineStaging: Record "EE Purch. Line Staging"; DocNo: Code[20]; LineNo: Integer)
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", Enum::"Purchase Document Type"::Order);
        PurchaseLine.Validate("Document No.", DocNo);
        PurchaseLine.Validate("Line No.", LineNo);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("No.", FleetRockSetup."Purchase G/L Account No.");
        PurchaseLine.Validate(Quantity, PurchLineStaging.part_quantity);
        PurchaseLine.Validate("Unit Cost", PurchLineStaging.unit_price);
        PurchaseLine.Validate("Direct Unit Cost", PurchLineStaging.unit_price);
        PurchaseLine.Description := CopyStr(PurchLineStaging.part_description, 1, MaxStrLen(PurchaseLine.Description));
        PurchaseLine.Validate("Tax Group Code", FleetrockSetup."Tax Group Code");
        PurchaseLine.Validate("EE Part Id", PurchLineStaging.part_id);
        PurchaseLine.Insert(true);
    end;



    local procedure PopulateStagingTable(var RecVar: Variant; var OrderJsonObj: JsonObject; TableNo: Integer; StartFieldNo: Integer)
    var
        FieldRec: Record Field;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        FieldRec.SetRange(TableNo, TableNo);
        FieldRec.SetRange("No.", StartFieldNo, 99);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Type, FieldRec.Type::Text);
        if FieldRec.FindSet() then
            repeat
                RecRef.Field(FieldRec."No.").Value(GetJsonValueAsText(OrderJsonObj, FieldRec.FieldName));
            until FieldRec.Next() = 0;
        FieldRec.SetRange(Type, FieldRec.Type::Decimal);
        if FieldRec.FindSet() then
            repeat
                RecRef.Field(FieldRec."No.").Value(GetJsonValueAsDecimal(OrderJsonObj, FieldRec.FieldName));
            until FieldRec.Next() = 0;
        RecRef.SetTable(RecVar);
    end;




    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", OnMoveGenJournalBatch, '', false, false)]
    local procedure GenJoournalBatchOnMoveGenJournalBatch(ToRecordID: RecordId)
    var
        RecRef: RecordRef;
    begin
        if RecRef.Get(ToRecordID) then
            if RecRef.Number() = Database::"G/L Register" then
                CheckForPaidCustLedgerEntries(RecRef);
    end;

    local procedure CheckForPaidCustLedgerEntries(var RecRef: RecordRef)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CustLedgerEntry, CustLedgerEntry2 : Record "Cust. Ledger Entry";
        GLRegister: Record "G/L Register";
        PaymentDateTime: DateTime;
    begin
        RecRef.SetTable(GLRegister);
        CustLedgerEntry.SetLoadFields("Entry No.", "Document Type", "Closed by Entry No.");
        CustLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        if not CustLedgerEntry.FindSet() then
            exit;
        CustLedgerEntry2.SetCurrentKey("Closed by Entry No.");
        CustLedgerEntry2.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        repeat
            CustLedgerEntry2.SetRange("Closed by Entry No.", CustLedgerEntry."Entry No.");
            if CustLedgerEntry2.FindFirst() then begin
                if SalesInvHeader.Get(CustLedgerEntry2."Document No.") then
                    if SalesInvHeader."EE Fleetrock ID" <> '' then begin
                        if CustLedgerEntry2."Closed at Date" = Today() then
                            PaymentDateTime := CurrentDateTime()
                        else
                            PaymentDateTime := CreateDateTime(CustLedgerEntry2."Closed at Date", Time());
                        UpdatePaidRepairOrder(SalesInvHeader."EE Fleetrock ID", PaymentDateTime);
                    end;
            end;

        until CustLedgerEntry.Next() = 0;
    end;

    local procedure UpdatePaidRepairOrder(OrderId: Text; PaidDateTime: DateTime)
    var
        ImportEntry: Record "EE Import/Export Entry";
        ResponseArray: JsonArray;
        JsonBody, ResponseObj : JsonObject;
        T: JsonToken;
        APIToken, URL : Text;
        EntryNo: Integer;
        Success: Boolean;
    begin
        if ImportEntry.FindLast() then
            EntryNo := ImportEntry."Entry No.";
        APIToken := CheckToGetAPIToken();
        URL := StrSubstNo('%1/API/UpdateRO?token=%2', FleetrockSetup."Integration URL", APIToken);
        JsonBody := CreateUpdateRepairOrderJsonBody(FleetrockSetup.Username, OrderId, PaidDateTime);
        if not RestAPIMgt.TryToGetResponseAsJsonArray(FleetrockSetup, URL, 'response', 'POST', JsonBody, ResponseArray) then begin
            InsertImportEntry(EntryNo + 1, false, 0, Enum::"EE Import Type"::"Repair Order", Enum::"EE Event Type"::Paid,
                Enum::"EE Direction"::Export, GetLastErrorText(), URL, 'POST', JsonBody);
            exit;
        end;
        if ResponseArray.Count() <> 0 then
            foreach T in ResponseArray do begin
                EntryNo += 1;
                ClearLastError();
                Success := TryToHandleRepairUpdateResponse(T, OrderId);
                InsertImportEntry(EntryNo, Success and (GetLastErrorText() = ''), 0, Enum::"EE Import Type"::"Repair Order",
                    Enum::"EE Event Type"::Paid, Enum::"EE Direction"::Export, GetLastErrorText(), URL, 'POST', JsonBody);
            end;
    end;

    [TryFunction]
    local procedure TryToHandleRepairUpdateResponse(var T: JsonToken; OrderId: Text)
    var
        ResponseArray: JsonArray;
        JsonBody, ResponseObj : JsonObject;
        s: Text;
    begin
        ResponseObj := T.AsObject();
        if not ResponseObj.Get('result', T) then begin
            ResponseObj.WriteTo(s);
            Error('Invalid response message:\%1', s);
        end;
        if T.AsValue().AsText() <> 'success' then begin
            ResponseObj.Get('ro_id', T);
            OrderId := T.AsValue().AsText();
            ResponseObj.Get('message', T);
            Error('Failed to update Repair Order %1:\%2', OrderId, T.AsValue().AsText());
        end;
    end;

    local procedure CreateUpdateRepairOrderJsonBody(UserName: Text; RepairOrderId: Text; PaidDateTime: DateTime): JsonObject
    var
        JsonBody, RepairOrder : JsonObject;
        RepairOrdersArray: JsonArray;
    begin
        RepairOrder.Add('ro_id', RepairOrderId);
        RepairOrder.Add('date_invoice_paid', Format(PaidDateTime, 0, 9));
        RepairOrdersArray.Add(RepairOrder);
        JsonBody.Add('username', UserName);
        JsonBody.Add('repair_orders', RepairOrdersArray);
        exit(JsonBody);
    end;










    procedure InsertImportEntry(EntryNo: Integer; Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type"; Direction: Enum "EE Direction"; ErrorMsg: Text; URL: Text; Method: Text)
    var
        JsonBody: JsonObject;
    begin
        InsertImportEntry(EntryNo, Success, ImportEntryNo, Type, EventType, Direction, ErrorMsg, URL, Method, JsonBody);
    end;

    procedure InsertImportEntry(EntryNo: Integer; Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type"; Direction: Enum "EE Direction"; ErrorMsg: Text; URL: Text; Method: Text; var JsonBody: JsonObject)
    var
        ImportEntry: Record "EE Import/Export Entry";
        s: Text;
    begin
        JsonBody.WriteTo(s);
        ImportEntry.Init();
        ImportEntry."Entry No." := EntryNo;
        ImportEntry."Document Type" := Type;
        ImportEntry.Success := Success;
        ImportEntry."Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(ImportEntry."Error Message"));
        ImportEntry."Import Entry No." := ImportEntryNo;
        ImportEntry."Event Type" := EventType;
        ImportEntry.URL := CopyStr(URL, 1, MaxStrLen(ImportEntry.URL));
        ImportEntry.Method := CopyStr(Method, 1, MaxStrLen(ImportEntry.Method));
        ImportEntry."Request Body" := CopyStr(s, 1, MaxStrLen(ImportEntry."Request Body"));
        ImportEntry.Direction := Direction;
        ImportEntry.Insert(true);
    end;


    var
        FleetrockSetup: Record "EE Fleetrock Setup";
        RestAPIMgt: Codeunit "EE REST API Mgt.";
}