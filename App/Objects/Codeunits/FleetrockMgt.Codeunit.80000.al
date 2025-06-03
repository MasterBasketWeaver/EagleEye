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
    tabledata "Purch. Inv. Header" = rm,
    tabledata "Purch. Inv. Line" = rm,
    tabledata "Sales Invoice Header" = rm,
    tabledata "Sales Invoice Line" = rm;



    local procedure GetAndCheckSetup()
    begin
        GetAndCheckSetup(false);
    end;

    local procedure GetAndCheckSetup(UseVendorKey: Boolean)
    begin
        FleetrockSetup.Get();
        FleetrockSetup.TestField("Integration URL");
        if UseVendorKey then begin
            FleetrockSetup.TestField("Vendor Username");
            FleetrockSetup.TestField("Vendor API Key");
        end else begin
            FleetrockSetup.TestField("Username");
            FleetrockSetup.TestField("API Key");
        end;
    end;

    procedure CheckToGetAPIToken(): Text
    begin
        exit(CheckToGetAPIToken(false));
    end;

    procedure CheckToGetAPIToken(UseVendorKey: Boolean): Text
    var
        ResponseText: Text;
    begin
        GetAndCheckSetup(UseVendorKey);
        if not FleetrockSetup."Use API Token" then
            if UseVendorKey then
                exit(FleetrockSetup."Vendor API Key")
            else
                exit(FleetrockSetup."API Key");
        if (FleetrockSetup."API Token" <> '') and (FleetrockSetup."API Token Expiry Date" >= Today()) then
            exit(FleetrockSetup."API Token");
        exit(CheckToGetAPIToken(FleetrockSetup, UseVendorKey));
    end;

    procedure CheckToGetAPIToken(var FleetrockSetup: Record "EE Fleetrock Setup"): Text
    begin
        exit(CheckToGetAPIToken(FleetrockSetup, false));
    end;

    procedure CheckToGetAPIToken(var FleetrockSetup: Record "EE Fleetrock Setup"; UseVendorKey: Boolean): Text
    var
        JsonTkn: JsonToken;
        Username, APIKey, s : Text;
    begin
        if UseVendorKey then begin
            Username := FleetrockSetup."Vendor Username";
            APIKey := FleetrockSetup."Vendor API Key";
        end else begin
            Username := FleetrockSetup.Username;
            APIKey := FleetrockSetup."API Key";
        end;
        JsonTkn := RestAPIMgt.GetResponseAsJsonToken('GET', StrSubstNo('%1/API/GetToken?username=%2&key=%3', FleetrockSetup."Integration URL", Username, APIKey), 'token');
        JsonTkn.WriteTo(s);
        s := s.Replace('"', '');
        FleetrockSetup.Validate("API Token", s);
        // FleetrockSetup.Validate("API Token Expiry Date", CalcDate('<+180D>', Today()));
        // FleetrockSetup.Validate("Use API Token", true);
        FleetrockSetup.Modify(true);
        exit(s);
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
        if not TryToInsertPurchStaging(OrderJsonObj, EntryNo) then begin
            if not PurchHeaderStaging.Get(EntryNo) then begin
                PurchHeaderStaging.Init();
                PurchHeaderStaging."Entry No." := EntryNo;
                PurchHeaderStaging.Insert(true);
            end;
            PurchHeaderStaging."Import Error" := true;
            PurchHeaderStaging."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(PurchHeaderStaging."Error Message"));
            PurchHeaderStaging.Modify(true);
            exit(EntryNo);
        end;
        PurchHeaderStaging.Get(EntryNo);
        if CreateOrder then begin
            if PurchHeaderStaging.Processed then
                Error('Staged Purchase Header %1 has already been processed.', PurchHeaderStaging."Entry No.");
            CreatePurchaseOrder(PurchHeaderStaging);
        end;
        exit(EntryNo);
    end;




    local procedure CheckPurchaseOrderSetup()
    begin
        FleetrockSetup.TestField("Purchase Item No.");
        FleetrockSetup.TestField("Vendor Posting Group");
        FleetrockSetup.TestField("Tax Area Code");
        FleetrockSetup.TestField("Non-Taxable Tax Group Code");
        FleetrockSetup.TestField("Payment Terms");
    end;

    procedure CreatePurchaseOrder(var PurchHeaderStaging: Record "EE Purch. Header Staging")
    var
        PurchaseHeader: Record "Purchase Header";
        DocNo: Code[20];
    begin
        GetAndCheckSetup();
        CheckPurchaseOrderSetup();

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
    procedure TryToCreatePurchaseOrder(var PurchHeaderStaging: Record "EE Purch. Header Staging"; var DocNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        CheckIfAlreadyImported(PurchHeaderStaging.id, PurchaseHeader);
        if PurchaseHeader."No." <> '' then begin
            UpdatePurchaseOrder(PurchHeaderStaging, PurchaseHeader);
            DocNo := PurchaseHeader."No.";
            exit;
        end;
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
        if PurchaseHeader."Payment Terms Code" = '' then
            if PurchHeaderStaging.payment_term_days = 0 then
                PurchaseHeader.Validate("Payment Terms Code", FleetrockSetup."Payment Terms")
            else
                PurchaseHeader.Validate("Payment Terms Code", GetPaymentTerms(PurchHeaderStaging.payment_term_days));
        PurchaseHeader.Validate("EE Fleetrock ID", PurchHeaderStaging.id);
        if PurchHeaderStaging.invoice_number <> '' then
            PurchaseHeader.Validate("Vendor Invoice No.", PurchHeaderStaging.invoice_number);
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
        repeat
            LineNo += 10000;
            AddPurchaseLine(PurchaseLine, PurchLineStaging, DocNo, LineNo);
        until PurchLineStaging.Next() = 0;
        if PurchHeaderStaging.tax_total <> 0 then
            AddExtraPurchLine(LineNo, DocNo, 'Taxes', PurchHeaderStaging.tax_total, GetTaxLineID());
        if PurchHeaderStaging.shipping_total <> 0 then
            AddExtraPurchLine(LineNo, DocNo, 'Shipping', PurchHeaderStaging.shipping_total, GetShippingLineID());
        if PurchHeaderStaging.other_total <> 0 then
            AddExtraPurchLine(LineNo, DocNo, 'Other Charges', PurchHeaderStaging.other_total, GetOtherLineID());
    end;


    local procedure AddExtraPurchLine(var LineNo: Integer; DocNo: Code[20]; Descr: Text; Amount: Decimal; LineID: Code[20])
    var
        PurchLine: Record "Purchase Line";
        PurchLineStaging: Record "EE Purch. Line Staging";
    begin
        LineNo += 10000;
        PurchLineStaging.Init();
        PurchLineStaging.part_quantity := 1;
        PurchLineStaging.unit_price := Amount;
        PurchLineStaging.part_description := Descr;
        PurchLineStaging.part_id := LineID;
        AddPurchaseLine(PurchLine, PurchLineStaging, DocNo, LineNo);
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
        if ImportId = '' then
            exit(false);
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
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetCurrentKey("EE Fleetrock ID");
        PurchInvHeader.SetRange("EE Fleetrock ID", ImportId);
        if PurchInvHeader.FindFirst() then
            Error('Fleetrock Purchase Order %1 has already been imported as order %2, and posted as invoice %3.', ImportId, PurchInvHeader."Order No.", PurchInvHeader."No.");
        PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
        PurchaseHeader.SetRange("EE Fleetrock ID", ImportId);
        if PurchaseHeader.FindFirst() then;
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
    begin
        if PurchHeaderStaging.supplier_name = '' then
            Error('supplier_name must be specified.');
        Vendor.SetRange("EE Source Type", Vendor."EE Source Type"::Fleetrock);
        Vendor.SetRange("EE Source No.", PurchHeaderStaging.supplier_name);
        if Vendor.FindFirst() then begin
            if GetVendorDetails(PurchHeaderStaging.supplier_name, VendorObj) then
                if UpdateVendorFromJson(Vendor, VendorObj) then
                    Vendor.Modify(true);
            if Vendor."Tax Area Code" = '' then begin
                Vendor.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
                Vendor.Modify(true);
            end;
            exit(Vendor."No.");
        end;

        if not GetVendorDetails(PurchHeaderStaging.supplier_name, VendorObj) then begin
            InitVendor(PurchHeaderStaging, Vendor);
            Vendor.Modify(true);
            exit(Vendor."No.");
        end;

        InitVendor(PurchHeaderStaging, Vendor);
        UpdateVendorFromJson(Vendor, VendorObj);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure UpdateVendorFromJson(var Vendor: Record Vendor; var VendorObj: JsonObject): Boolean
    var
        Vendor2: Record Vendor;
        PaymentTermsCode: Code[10];
        PaymentTermDays: Integer;
        PhoneNo: Text;
    begin
        Vendor2 := Vendor;
        if Vendor.Address <> JsonMgt.GetJsonValueAsText(VendorObj, 'street_address_1') then
            Vendor.Validate(Address, JsonMgt.GetJsonValueAsText(VendorObj, 'street_address_1'));
        if Vendor."Address 2" <> JsonMgt.GetJsonValueAsText(VendorObj, 'street_address_2') then
            Vendor.Validate("Address 2", JsonMgt.GetJsonValueAsText(VendorObj, 'street_address_2'));
        if Vendor."City" <> JsonMgt.GetJsonValueAsText(VendorObj, 'city') then
            Vendor.Validate("City", JsonMgt.GetJsonValueAsText(VendorObj, 'city'));
        if Vendor."County" <> JsonMgt.GetJsonValueAsText(VendorObj, 'state') then
            Vendor.Validate(County, JsonMgt.GetJsonValueAsText(VendorObj, 'state'));
        if Vendor."Country/Region Code" <> JsonMgt.GetJsonValueAsText(VendorObj, 'country') then
            Vendor."Country/Region Code" := JsonMgt.GetJsonValueAsText(VendorObj, 'country');
        if Vendor."Post Code" <> JsonMgt.GetJsonValueAsText(VendorObj, 'zip_code') then
            Vendor.Validate("Post Code", JsonMgt.GetJsonValueAsText(VendorObj, 'zip_code'));
        PhoneNo := JsonMgt.GetJsonValueAsText(VendorObj, 'phone');
        if not TryToSetVendorNo(Vendor, PhoneNo) then
            Vendor."Phone No." := PhoneNo;
        if Vendor."E-Mail" <> JsonMgt.GetJsonValueAsText(VendorObj, 'email') then
            Vendor.Validate("E-Mail", JsonMgt.GetJsonValueAsText(VendorObj, 'email'));
        PaymentTermDays := Round(JsonMgt.GetJsonValueAsDecimal(VendorObj, 'payment_term_days'), 1);
        if PaymentTermDays = 0 then
            PaymentTermsCode := FleetrockSetup."Payment Terms"
        else
            PaymentTermsCode := GetPaymentTerms(PaymentTermDays);
        if Vendor."Payment Terms Code" <> PaymentTermsCode then
            Vendor.Validate("Payment Terms Code", PaymentTermsCode);

        exit((Vendor.Address <> Vendor2.Address)
            or (Vendor2."Address 2" <> Vendor."Address 2")
            or (Vendor2."City" <> Vendor."City")
            or (Vendor2."County" <> Vendor."County")
            or (Vendor2."Country/Region Code" <> Vendor."Country/Region Code")
            or (Vendor2."Post Code" <> Vendor."Post Code")
            or (Vendor2."Phone No." <> Vendor."Phone No.")
            or (Vendor2."E-Mail" <> Vendor."E-Mail")
            or (Vendor2."Payment Terms Code" <> Vendor."Payment Terms Code"));
    end;

    [TryFunction]
    local procedure TryToSetVendorNo(var Vendor: Record Vendor; PhoneNo: Text)
    begin
        Vendor.Validate("Phone No.", PhoneNo);
    end;

    local procedure InitVendor(var PurchHeaderStaging: Record "EE Purch. Header Staging"; var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor.Insert(true);
        Vendor.Validate(Name, PurchHeaderStaging.supplier_name);
        Vendor.Validate("EE Source Type", Vendor."EE Source Type"::Fleetrock);
        Vendor.Validate("EE Source No.", PurchHeaderStaging.supplier_name);
        Vendor.Validate("Vendor Posting Group", FleetrockSetup."Vendor Posting Group");
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
    end;




    local procedure GetVendorDetails(SupplierName: Text; var VendorObj: JsonObject): Boolean
    var
        VendorArray: JsonArray;
        T: JsonToken;
    begin
        CheckToGetAPIToken();
        VendorArray := RestAPIMgt.GetResponseAsJsonArray(StrSubstNo('%1/API/GetSuppliers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, CheckToGetAPIToken()), 'suppliers');
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
        if Customer.FindFirst() then begin
            if GetCustomerDetails(SourceNo, IsSourceCompany, CustomerObj) then
                if UpdateCustomerFromJson(Customer, CustomerObj) then
                    Customer.Modify(true);
            exit(Customer."No.");
        end;

        if not GetCustomerDetails(SourceNo, IsSourceCompany, CustomerObj) then begin
            InitCustomer(SalesHeaderStaging, Customer, SourceNo);
            Customer.Modify(true);
            exit(Customer."No.");
        end;

        InitCustomer(SalesHeaderStaging, Customer, SourceNo);
        UpdateCustomerFromJson(Customer, CustomerObj);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure UpdateCustomerFromJson(var Customer: Record Customer; var CustomerObj: JsonObject): Boolean
    var
        Customer2: Record Customer;
        Name, PhoneNo : Text;
        PaymentTermsCode: Code[10];
        PaymentTermDays: Integer;
    begin
        Customer2 := Customer;
        if Customer.Address <> JsonMgt.GetJsonValueAsText(CustomerObj, 'street_address') then
            Customer.Validate(Address, JsonMgt.GetJsonValueAsText(CustomerObj, 'street_address'));
        if Customer."City" <> JsonMgt.GetJsonValueAsText(CustomerObj, 'city') then
            Customer.Validate("City", JsonMgt.GetJsonValueAsText(CustomerObj, 'city'));
        if Customer."County" <> JsonMgt.GetJsonValueAsText(CustomerObj, 'state') then
            Customer.Validate(County, JsonMgt.GetJsonValueAsText(CustomerObj, 'state'));
        if Customer."Country/Region Code" <> JsonMgt.GetJsonValueAsText(CustomerObj, 'country') then
            Customer."Country/Region Code" := JsonMgt.GetJsonValueAsText(CustomerObj, 'country');
        if Customer."Post Code" <> JsonMgt.GetJsonValueAsText(CustomerObj, 'zip_code') then
            Customer.Validate("Post Code", JsonMgt.GetJsonValueAsText(CustomerObj, 'zip_code'));
        PhoneNo := JsonMgt.GetJsonValueAsText(CustomerObj, 'phone');
        if not TryToSetCustomerNo(Customer, PhoneNo) then
            Customer."Phone No." := PhoneNo;
        Name := StrSubstNo('%1 %2', JsonMgt.GetJsonValueAsText(CustomerObj, 'first_name'), JsonMgt.GetJsonValueAsText(CustomerObj, 'last_name')).Trim();
        if Customer.Name <> Name then
            Customer.Validate(Name, Name);
        if Customer."Name 2" <> JsonMgt.GetJsonValueAsText(CustomerObj, 'company_name') then
            Customer.Validate("Name 2", CopyStr(JsonMgt.GetJsonValueAsText(CustomerObj, 'company_name'), 1, MaxStrLen(Customer."Name 2")));

        exit((Customer.Address <> Customer2.Address)
            or (Customer2."City" <> Customer."City")
            or (Customer2."County" <> Customer."County")
            or (Customer2."Country/Region Code" <> Customer."Country/Region Code")
            or (Customer2."Post Code" <> Customer."Post Code")
            or (Customer2."Phone No." <> Customer."Phone No.")
            or (Customer2.Name <> Customer.Name));
    end;


    [TryFunction]

    local procedure TryToSetCustomerNo(var Customer: Record Customer; PhoneNo: Text)
    begin
        Customer.Validate("Phone No.", PhoneNo);
    end;

    local procedure InitCustomer(var SalesHeaderStaging: Record "EE Sales Header Staging"; var Customer: Record Customer; SourceNo: Text)
    begin
        Customer.Init();
        Customer.Insert(true);
        Customer.Validate(Name, SalesHeaderStaging.customer_name);
        Customer.Validate("EE Source Type", Customer."EE Source Type"::Fleetrock);
        Customer.Validate("EE Source No.", SourceNo);
        Customer.Validate("Payment Terms Code", FleetrockSetup."Payment Terms");
        Customer.Validate("Customer Posting Group", FleetrockSetup."Customer Posting Group");
        Customer.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
        Customer.Validate("Tax Liable", true);
    end;


    local procedure GetCustomerDetails(SourceValue: Text; IsSourceCompany: Boolean; var CustomerObj: JsonObject): Boolean
    var
        CustomerArray: JsonArray;
        T: JsonToken;
        SourceType: Text;
    begin
        CheckToGetAPIToken();
        CustomerArray := RestAPIMgt.GetResponseAsJsonArray(StrSubstNo('%1/API/GetUsers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, CheckToGetAPIToken()), 'users');
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

    procedure GetPaymentTerms(PaymentTermsDays: Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        DateForm: DateFormula;
    begin
        if PaymentTermsDays <= 0 then
            Error('Payment Term Days must be greater than zero: %1.', PaymentTermsDays);
        Evaluate(DateForm, StrSubstNo('<%1D>', PaymentTermsDays));
        PaymentTerms.SetRange("Due Date Calculation", DateForm);
        PaymentTerms.SetFilter(Code, '%1|%2', StrSubstNo('NET%1', PaymentTermsDays), StrSubstNo('%1 DAYS', PaymentTermsDays));
        if PaymentTerms.FindFirst() then
            exit(PaymentTerms.Code);
        PaymentTerms.SetRange(Code);
        PaymentTerms.SetFilter(Description, StrSubstNo('*%1*', PaymentTermsDays));
        if PaymentTerms.FindFirst() then
            exit(PaymentTerms.Code);
        PaymentTerms.Init();
        PaymentTerms.Validate(Code, StrSubstNo('%1D', PaymentTermsDays));
        PaymentTerms.Validate(Description, StrSubstNo('%1 days', PaymentTermsDays));
        PaymentTerms.Validate("Due Date Calculation", DateForm);
        PaymentTerms.Insert(true);
        exit(PaymentTerms.Code);
    end;


    [TryFunction]
    local procedure TryToInsertPurchStaging(var OrderJsonObj: JsonObject; var EntryNo: Integer)
    var
        PurchHeaderStaging: Record "EE Purch. Header Staging";
        PurchLineStaging: Record "EE Purch. Line Staging";
        Lines: JsonArray;
        LineJsonObj: JsonObject;
        T: JsonToken;
        LineEntryNo: Integer;
    begin
        if PurchHeaderStaging.FindLast() then
            EntryNo := PurchHeaderStaging."Entry No.";
        EntryNo += 1;
        PurchHeaderStaging.Init();
        PurchHeaderStaging."Entry No." := EntryNo;
        PurchHeaderStaging.id := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'id');
        PurchHeaderStaging.supplier_name := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'supplier_name');
        PurchHeaderStaging.supplier_custom_id := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'supplier_custom_id');
        PurchHeaderStaging.recipient_name := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'recipient_name');
        PurchHeaderStaging.tag := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'tag');
        PurchHeaderStaging.status := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'status');
        PurchHeaderStaging.date_created := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'date_created');
        PurchHeaderStaging.date_opened := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'date_opened');
        PurchHeaderStaging.date_received := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'date_received');
        PurchHeaderStaging.date_closed := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'date_closed');
        PurchHeaderStaging.payment_term_days := JsonMgt.GetJsonValueAsDecimal(OrderJsonObj, 'payment_term_days');
        PurchHeaderStaging.invoice_number := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'invoice_number');
        PurchHeaderStaging.subtotal := JsonMgt.GetJsonValueAsDecimal(OrderJsonObj, 'subtotal');
        PurchHeaderStaging.tax_total := JsonMgt.GetJsonValueAsDecimal(OrderJsonObj, 'tax_total');
        PurchHeaderStaging.shipping_total := JsonMgt.GetJsonValueAsDecimal(OrderJsonObj, 'shipping_total');
        PurchHeaderStaging.other_total := JsonMgt.GetJsonValueAsDecimal(OrderJsonObj, 'other_total');
        PurchHeaderStaging.grand_total := JsonMgt.GetJsonValueAsDecimal(OrderJsonObj, 'grand_total');
        PurchHeaderStaging.Insert(true);

        PurchLineStaging.LockTable();
        if PurchLineStaging.FindLast() then
            LineEntryNo := PurchLineStaging."Entry No."
        else
            LineEntryNo := 0;
        OrderJsonObj.Get('line_items', T);
        Lines := T.AsArray();
        foreach T in Lines do begin
            LineEntryNo += 1;
            LineJsonObj := T.AsObject();
            PurchLineStaging.Init();
            PurchLineStaging."Entry No." := LineEntryNo;
            PurchLineStaging."Header Entry No." := PurchHeaderStaging."Entry No.";
            PurchLineStaging."Header id" := PurchHeaderStaging.id;
            PurchLineStaging.part_id := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_id');
            PurchLineStaging.part_number := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_number');
            PurchLineStaging.part_description := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_description');
            PurchLineStaging.part_system_code := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_system_code');
            PurchLineStaging.part_type := JsonMgt.GetJsonValueAsText(LineJsonObj, 'part_type');
            PurchLineStaging.tag := JsonMgt.GetJsonValueAsText(LineJsonObj, 'tag');
            PurchLineStaging.part_quantity := JsonMgt.GetJsonValueAsDecimal(LineJsonObj, 'part_quantity');
            PurchLineStaging.unit_price := JsonMgt.GetJsonValueAsDecimal(LineJsonObj, 'unit_price');
            PurchLineStaging.line_total := JsonMgt.GetJsonValueAsDecimal(LineJsonObj, 'line_total');
            PurchLineStaging.date_added := JsonMgt.GetJsonValueAsText(LineJsonObj, 'date_added');
            PurchLineStaging.Insert(true);
        end;
    end;







    procedure GetUnits()
    var
        APIToken: Text;
        JsonArry: JsonArray;
        T: JsonToken;
        UnitJsonObj: JsonObject;
    begin
        APIToken := CheckToGetAPIToken();
        JsonArry := RestAPIMgt.GetResponseAsJsonArray(StrSubstNo('%1/API/GetUnits?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, APIToken), 'units');
        foreach T in JsonArry do begin
            UnitJsonObj := T.AsObject();
        end;
    end;


    procedure GetSuppliers(): JsonArray
    var
        APIToken: Text;
    begin
        APIToken := CheckToGetAPIToken();
        exit(RestAPIMgt.GetResponseAsJsonArray(StrSubstNo('%1/API/GetSuppliers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, APIToken), 'suppliers'));
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
        exit(RestAPIMgt.GetResponseAsJsonArray(StrSubstNo('%1/API/GetPO?username=%2&status=%3&token=%4', FleetrockSetup."Integration URL", FleetrockSetup.Username, Status, APIToken), 'purchase_orders'));
    end;

    procedure GetPurchaseOrder(DocId: Text): JsonArray
    var
        APIToken: Text;
    begin
        APIToken := CheckToGetAPIToken();
        exit(RestAPIMgt.GetResponseAsJsonArray(StrSubstNo('%1/API/GetPO?username=%2&id=%3&token=%4', FleetrockSetup."Integration URL", FleetrockSetup.Username, DocId, APIToken), 'purchase_orders'));
    end;



    [TryFunction]
    procedure TryToGetPurchaseOrders(StartDateTime: DateTime; var PurchOrdersJsonArray: JsonArray; var URL: Text; EventType: Enum "EE Event Type")
    begin
        PurchOrdersJsonArray := GetPurchaseOrders(StartDateTime, URL, EventType);
    end;


    procedure GetPurchaseOrders(StartDateTime: DateTime; var URL: Text; EventType: Enum "EE Event Type"): JsonArray
    var
        APIToken: Text;
        EndDateTime: DateTime;
    begin
        GetEventParameters(APIToken, StartDateTime, EndDateTime, false);
        URL := StrSubstNo('%1/API/GetPO?username=%2&event=%3&token=%4&start=%5&end=%6', FleetrockSetup."Integration URL",
            FleetrockSetup.Username, EventType, APIToken, Format(StartDateTime, 0, 9), Format(EndDateTime, 0, 9));
        exit(RestAPIMgt.GetResponseAsJsonArray(URL, 'purchase_orders'));
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
        GetEventParameters(APIToken, StartDateTime, EndDateTime, true);
        URL := StrSubstNo('%1/API/GetRO?username=%2&event=%3&token=%4&start=%5&end=%6', FleetrockSetup."Integration URL",
            FleetrockSetup.Username, Status, APIToken, Format(StartDateTime, 0, 9), Format(EndDateTime, 0, 9));
        exit(RestAPIMgt.GetResponseAsJsonArray(URL, 'repair_orders'));
    end;



    local procedure GetEventParameters(var APIToken: Text; var StartDateTime: DateTime; var EndDateTime: DateTime; UseVendorKey: Boolean)
    begin
        APIToken := CheckToGetAPIToken();
        if UseVendorKey then
            CheckToGetAPIToken(true);
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
        if not TryToInsertSalesStaging(OrderJsonObj, EntryNo) then begin
            if not SalesHeaderStaging.Get(EntryNo) then begin
                SalesHeaderStaging.Init();
                SalesHeaderStaging."Entry No." := EntryNo;
                SalesHeaderStaging.Insert(true);
            end;
            SalesHeaderStaging."Import Error" := true;
            SalesHeaderStaging."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(SalesHeaderStaging."Error Message"));
            SalesHeaderStaging.Modify(true);
            exit(EntryNo);
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
    local procedure TryToInsertSalesStaging(var OrderJsonObj: JsonObject; var EntryNo: Integer)
    var
        SalesHeaderStaging: Record "EE Sales Header Staging";
        TaskLineStaging: Record "EE Task Line Staging";
        PartLineStaging: Record "EE Part Line Staging";
        UnitCosts: Dictionary of [Text, Decimal];
        TaskLines, PartLines : JsonArray;
        TaskLineJsonObj, PartLineJsonObj, PartObj : JsonObject;
        T: JsonToken;
        RecVar: Variant;
        APIToken, VendorAPIToken : Text;
        LineEntryNo, PartEntryNo : Integer;
    begin
        SalesHeaderStaging.LockTable();
        if SalesHeaderStaging.FindLast() then
            EntryNo := SalesHeaderStaging."Entry No.";
        EntryNo += 1;
        SalesHeaderStaging.Init();
        SalesHeaderStaging."Entry No." := EntryNo;
        RecVar := SalesHeaderStaging;

        PopulateStagingTable(RecVar, OrderJsonObj, Database::"EE Sales Header Staging", SalesHeaderStaging.FieldNo(id));
        SalesHeaderStaging := RecVar;
        if FleetrockSetup."Internal Customer Names" <> '' then
            if FleetrockSetup."Internal Customer Names".Contains('|') then
                SalesHeaderStaging."Internal Customer" := IsInternalCustomer(FleetrockSetup."Internal Customer Names", SalesHeaderStaging.customer_name)
            else
                SalesHeaderStaging."Internal Customer" := SalesHeaderStaging.customer_name = FleetrockSetup."Internal Customer Names";
        SalesHeaderStaging.Insert(true);

        if not OrderJsonObj.Get('tasks', T) then
            exit;
        TaskLines := T.AsArray();
        if TaskLines.Count() = 0 then
            exit;
        TaskLineStaging.LockTable();
        if TaskLineStaging.FindLast() then
            LineEntryNo := TaskLineStaging."Entry No."
        else
            LineEntryNo := 0;
        PartLineStaging.LockTable();
        if PartLineStaging.FindLast() then
            PartEntryNo := PartLineStaging."Entry No.";
        foreach T in TaskLines do begin
            LineEntryNo += 1;
            TaskLineJsonObj := T.AsObject();
            TaskLineStaging.Init();
            TaskLineStaging."Entry No." := LineEntryNo;
            TaskLineStaging."Header Entry No." := SalesHeaderStaging."Entry No.";
            TaskLineStaging."Header Id" := SalesHeaderStaging.id;
            RecVar := TaskLineStaging;
            PopulateStagingTable(RecVar, TaskLineJsonObj, Database::"EE Task Line Staging", TaskLineStaging.FieldNo("task_id"));
            TaskLineStaging := RecVar;
            TaskLineStaging.Insert(true);
            if TaskLineJsonObj.Get('parts', T) then begin
                APIToken := CheckToGetAPIToken();
                VendorAPIToken := CheckToGetAPIToken(true);
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
                    if UnitCosts.ContainsKey(PartLineStaging.part_id) then
                        PartLineStaging."Unit Cost" := UnitCosts.Get(PartLineStaging.part_id)
                    else begin
                        ClearLastError();
                        if TryToGetPart(PartLineStaging.part_id, VendorAPIToken, PartLineStaging."Loaded Part Details", PartObj) and PartLineStaging."Loaded Part Details" then
                            PartLineStaging."Unit Cost" := JsonMgt.GetJsonValueAsDecimal(PartObj, 'part_cost')
                        else
                            PartLineStaging."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(PartLineStaging."Error Message"));
                        UnitCosts.Add(PartLineStaging.part_id, PartLineStaging."Unit Cost");
                    end;
                    PartLineStaging.Insert(true);
                end;
            end;
        end;
    end;



    [TryFunction]
    local procedure TryToGetPart(PartId: Text; var APIToken: Text; var Success: Boolean; var JsonObj: JsonObject)
    begin
        Success := GetPart(PartId, APIToken, JsonObj);
    end;

    local procedure GetPart(PartId: Text; var APIToken: Text; var JsonObj: JsonObject): Boolean
    var
        JsonArry: JsonArray;
        JsonToken: JsonToken;
        URL: Text;
    begin
        if APIToken = '' then
            APIToken := CheckToGetAPIToken(true);
        URL := StrSubstNo('%1/API/GetParts?username=%2&token=%3&id=%4', FleetrockSetup."Integration URL", FleetrockSetup."Vendor Username", APIToken, PartId);
        JsonArry := RestAPIMgt.GetResponseAsJsonArray(URL, 'parts');
        JsonArry.WriteTo(URL);
        if (JsonArry.Count() = 0) or not JsonArry.Get(0, JsonToken) then
            exit(false);
        JsonObj := JsonToken.AsObject();
        exit(true);
    end;




    local procedure IsInternalCustomer(InternalNames: Text; OrderName: Text): Boolean
    var
        CustomerNames: List of [Text];
    begin
        CustomerNames := InternalNames.Split('|');
        exit(CustomerNames.Contains(OrderName));
    end;



    local procedure CheckRepairOrderSetup()
    begin
        FleetrockSetup.TestField("External Labor Item No.");
        FleetrockSetup.TestField("External Parts Item No.");
        if FleetrockSetup."Internal Customer Names" <> '' then begin
            FleetrockSetup.TestField("Internal Labor Item No.");
            FleetrockSetup.TestField("Internal Parts Item No.");
        end;
        FleetrockSetup.TestField("Customer Posting Group");
        FleetrockSetup.TestField("Tax Jurisdiction Code");
        FleetrockSetup.TestField("Tax Area Code");
        FleetrockSetup.TestField("Labor Tax Group Code");
        FleetrockSetup.TestField("Parts Tax Group Code");
        FleetrockSetup.TestField("Fees Tax Group Code");
        FleetrockSetup.TestField("Non-Taxable Tax Group Code");
        FleetrockSetup.TestField("Payment Terms");
    end;


    procedure CreateSalesOrder(var SalesHeaderStaging: Record "EE Sales Header Staging")
    var
        SalesaseHeader: Record "Sales Header";
        DocNo: Code[20];
    begin
        GetAndCheckSetup();
        CheckRepairOrderSetup();
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
            AddTaskSalesLine(SalesLine, TaskLineStaging, DocNo, LineNo, SalesHeaderStaging."Internal Customer");
            if TaskLineStaging."Part Lines" > 0 then begin
                PartLineStaging.SetRange("Task Entry No.", TaskLineStaging."Entry No.");
                PartLineStaging.SetRange("Task Id", TaskLineStaging.task_id);
                if PartLineStaging.FindSet() then
                    repeat
                        AddPartSalesLine(SalesLine, PartLineStaging, DocNo, LineNo, SalesHeaderStaging."Internal Customer");
                    until PartLineStaging.Next() = 0;
            end;
        until TaskLineStaging.Next() = 0;
        if SalesHeaderStaging.additional_charges > 0 then
            AddFeeSalesLine(SalesLine, DocNo, LineNo, SalesHeaderStaging.additional_charges, SalesHeaderStaging.additional_charges_tax_rate);
    end;

    local procedure AddTaskSalesLine(var SalesLine: Record "Sales Line"; var TaskLineStaging: Record "EE Task Line Staging"; DocNo: Code[20]; var LineNo: Integer; Internal: Boolean)
    var
        TaxGroupCode: Code[20];
    begin
        if TaskLineStaging.labor_hours = 0 then
            exit;
        LineNo += 10000;
        SalesLine.Init();
        SalesLine.Validate("Document Type", Enum::"Sales Document Type"::Invoice);
        SalesLine.Validate("Document No.", DocNo);
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        if Internal then
            SalesLine.Validate("No.", FleetRockSetup."Internal Labor Item No.")
        else
            SalesLine.Validate("No.", FleetRockSetup."External Labor Item No.");
        SalesLine.Validate("Qty. Rounding Precision", 0);
        SalesLine.Validate("Qty. Rounding Precision (Base)", 0);
        SalesLine.Validate(Quantity, TaskLineStaging.labor_hours);
        SalesLine.Validate("Unit Price", TaskLineStaging.labor_hourly_rate);
        if FleetrockSetup."Labor Cost" <> 0 then
            SalesLine.Validate("Unit Cost (LCY)", FleetrockSetup."Labor Cost");
        SalesLine.Description := CopyStr(TaskLineStaging.labor_system_code, 1, MaxStrLen(SalesLine.Description));

        SetTaxGroupCode(SalesLine, TaskLineStaging.labor_tax_rate, FleetrockSetup."Labor Tax Group Code");
        SalesLine.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");

        SalesLine.Validate("EE Updated", true);
        SalesLine.Validate("EE Task/Part Id", TaskLineStaging.task_id);
        SalesLine.Insert(true);
    end;

    local procedure AddPartSalesLine(var SalesLine: Record "Sales Line"; var PartLineStaging: Record "EE Part Line Staging"; DocNo: Code[20]; var LineNo: Integer; Internal: Boolean)
    var
        TaxGroupCode: Code[20];
    begin
        if PartLineStaging.part_quantity = 0 then
            exit;
        LineNo += 10000;
        SalesLine.Init();
        SalesLine.Validate("Document Type", Enum::"Sales Document Type"::Invoice);
        SalesLine.Validate("Document No.", DocNo);
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        if Internal then
            SalesLine.Validate("No.", FleetRockSetup."Internal Parts Item No.")
        else
            SalesLine.Validate("No.", FleetRockSetup."External Parts Item No.");
        SalesLine.Validate("Qty. Rounding Precision", 0);
        SalesLine.Validate("Qty. Rounding Precision (Base)", 0);
        SalesLine.Validate(Quantity, PartLineStaging.part_quantity);
        if PartLineStaging."Unit Cost" <> 0 then
            SalesLine.Validate("Unit Cost (LCY)", PartLineStaging."Unit Cost");
        SalesLine.Validate("Unit Price", PartLineStaging.part_price);
        SalesLine.Description := CopyStr(PartLineStaging.part_description, 1, MaxStrLen(SalesLine.Description));

        SetTaxGroupCode(SalesLine, PartLineStaging.part_tax_rate, FleetrockSetup."Parts Tax Group Code");
        SalesLine.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");

        SalesLine.Validate("EE Updated", true);
        SalesLine.Validate("EE Task/Part Id", PartLineStaging.task_part_id);
        SalesLine.Insert(true);
    end;

    local procedure AddFeeSalesLine(var SalesLine: Record "Sales Line"; DocNo: Code[20]; var LineNo: Integer; FeeAmount: Decimal; FeeTaxRate: Decimal)
    var
        TaxGroupCode: Code[20];
    begin
        LineNo += 10000;
        SalesLine.Init();
        SalesLine.Validate("Document Type", Enum::"Sales Document Type"::Invoice);
        SalesLine.Validate("Document No.", DocNo);
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", FleetRockSetup."Additional Fee's G/L No.");
        SalesLine.Validate("Qty. Rounding Precision", 0);
        SalesLine.Validate("Qty. Rounding Precision (Base)", 0);
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", FeeAmount);
        SalesLine.Description := 'Additional Fees';

        SetTaxGroupCode(SalesLine, FeeTaxRate, FleetrockSetup."Fees Tax Group Code");
        SalesLine.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");

        SalesLine.Validate("EE Task/Part Id", GetFeesLineID());
        SalesLine.Validate("EE Updated", true);
        SalesLine.Insert(true);
    end;



    local procedure SetTaxGroupCode(var SalesLine: Record "Sales Line"; TaxRate: Decimal; TaxGroupType: Code[20])
    var
        TaxGroupCode: Code[20];
    begin
        if TaxRate > 0 then
            TaxGroupCode := CheckToAddNewTaxRate(FleetrockSetup."Tax Jurisdiction Code", TaxGroupType, TaxRate);
        if TaxGroupCode <> '' then
            SalesLine.Validate("Tax Group Code", TaxGroupCode)
        else
            SalesLine.Validate("Tax Group Code", FleetrockSetup."Non-Taxable Tax Group Code");
    end;


    local procedure CheckToAddNewTaxRate(TaxJuriCode: Code[10]; TaxGroupCode: Code[20]; TaxAmount: Decimal): Code[20]
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxAmount := Round(TaxAmount, 0.01);
        if TaxAmount <= 0 then
            exit('');
        TaxGroupCode := StrSubstNo('%1-%2', TaxGroupCode, TaxAmount);
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJuriCode);
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
        if TaxDetail.IsEmpty() then
            AddTaxDetail(TaxJuriCode, TaxGroupCode, TaxAmount);
        exit(TaxGroupCode);
    end;

    local procedure AddTaxDetail(TaxJuriCode: Code[10]; TaxGroupCode: Code[20]; TaxAmount: Decimal)
    var
        TaxDetail: Record "Tax Detail";
        TaxGroup: Record "Tax Group";
        S: Text;
    begin
        if not TaxGroup.Get(TaxGroupCode) then begin
            TaxGroup.Init();
            TaxGroup.Validate(Code, TaxGroupCode);
            s := CopyStr(TaxGroupCode, 2).ToLower();
            if s.Contains('-') then
                s := CopyStr(s, 1, s.IndexOf('-') - 1);
            s := TaxGroupCode[1] + s;
            TaxGroup.Validate(Description, StrSubstNo('%1 taxes of %2.', s, TaxAmount));
            TaxGroup.Insert(true);
        end;
        TaxDetail.Init();
        TaxDetail.Validate("Tax Jurisdiction Code", TaxJuriCode);
        TaxDetail.Validate("Tax Group Code", TaxGroupCode);
        TaxDetail.Validate("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
        TaxDetail.Validate("Tax Below Maximum", TaxAmount);
        TaxDetail.Insert(true);
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
        GetAndCheckSetup();
        CheckRepairOrderSetup();
        GetCustomerNo(SalesHeaderStaging);
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, DocNo);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", DT2Date(SalesHeaderStaging."Invoiced At"));
        SalesHeader.Modify(true);
        if SalesHeaderStaging."Document No." <> SalesHeader."No." then begin
            SalesHeaderStaging.Validate("Document No.", SalesHeader."No.");
            SalesHeaderStaging.Modify(true);
        end;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No.";
        SalesLine.SetRange("EE Task/Part Id", GetFeesLineID());
        if SalesHeaderStaging.additional_charges <> 0 then
            if SalesLine.FindFirst() then begin
                SalesLine.Validate("Unit Price", SalesHeaderStaging.additional_charges);
                SetTaxGroupCode(SalesLine, SalesHeaderStaging.additional_charges_tax_rate, FleetrockSetup."Fees Tax Group Code");
                SalesLine.Validate("EE Updated", true);
                SalesLine.Modify(true);
            end else
                AddFeeSalesLine(SalesLine, SalesHeader."No.", LineNo, SalesHeaderStaging.additional_charges, SalesHeaderStaging.additional_charges_tax_rate)
        else
            if SalesLine.FindFirst() then
                SalesLine.Delete(true);

        TaskLineStaging.SetCurrentKey("Header Id", "Header Entry No.");
        TaskLineStaging.SetRange("Header Id", SalesHeaderStaging.id);
        TaskLineStaging.SetRange("Header Entry No.", SalesHeaderStaging."Entry No.");
        TaskLineStaging.SetAutoCalcFields("Part Lines");
        SalesLine.SetRange("EE Task/Part Id");
        if not TaskLineStaging.FindSet() then begin
            SalesLine.DeleteAll(true);
            exit;
        end;
        PartLineStaging.SetCurrentKey("Header Id", "Header Entry No.", "Task Entry No.", "Task Id");
        PartLineStaging.SetRange("Header Id", SalesHeaderStaging.id);
        PartLineStaging.SetRange("Header Entry No.", SalesHeaderStaging."Entry No.");

        DescrLength := MaxStrLen(SalesLine.Description);
        SalesLine.SetFilter("EE Task/Part Id", '<>%1', GetFeesLineID());
        SalesLine.ModifyAll("EE Updated", false);
        repeat
            SalesLine.SetRange("EE Task/Part Id", TaskLineStaging.task_id);
            if SalesLine.FindFirst() then begin
                SalesLine.Validate("Qty. Rounding Precision", 0);
                SalesLine.Validate("Qty. Rounding Precision (Base)", 0);
                SalesLine.Validate(Quantity, TaskLineStaging.labor_hours);
                SalesLine.Validate("Unit Price", TaskLineStaging.labor_hourly_rate);
                SalesLine.Description := CopyStr(TaskLineStaging.labor_system_code, 1, DescrLength);
                SalesLine.Validate("EE Updated", true);
                SetTaxGroupCode(SalesLine, TaskLineStaging.labor_tax_rate, FleetrockSetup."Labor Tax Group Code");
                SalesLine.Modify(true);
            end else
                AddTaskSalesLine(SalesLine, TaskLineStaging, SalesHeader."No.", LineNo, SalesHeaderStaging."Internal Customer");
            if TaskLineStaging."Part Lines" > 0 then begin
                PartLineStaging.SetRange("Task Entry No.", TaskLineStaging."Entry No.");
                PartLineStaging.SetRange("Task Id", TaskLineStaging.task_id);
                if PartLineStaging.FindSet() then
                    repeat
                        SalesLine.SetRange("EE Task/Part Id", PartLineStaging.task_part_id);
                        if SalesLine.FindFirst() then begin
                            SalesLine.Validate("Qty. Rounding Precision", 0);
                            SalesLine.Validate("Qty. Rounding Precision (Base)", 0);
                            SalesLine.Validate(Quantity, PartLineStaging.part_quantity);
                            SalesLine.Validate("Unit Cost (LCY)", PartLineStaging."Unit Cost");
                            SalesLine.Validate("Unit Price", PartLineStaging.part_price);
                            SalesLine.Description := CopyStr(PartLineStaging.part_description, 1, DescrLength);
                            SalesLine.Validate("EE Updated", true);
                            SetTaxGroupCode(SalesLine, PartLineStaging.part_tax_rate, FleetrockSetup."Parts Tax Group Code");
                            SalesLine.Modify(true);
                        end else
                            AddPartSalesLine(SalesLine, PartLineStaging, SalesHeader."No.", LineNo, SalesHeaderStaging."Internal Customer");
                    until PartLineStaging.Next() = 0;
            end;
        until TaskLineStaging.Next() = 0;
        SalesLine.SetRange("EE Task/Part Id");
        SalesLine.SetRange("EE Updated", false);
        SalesLine.DeleteAll(true);
    end;

    [TryFunction]
    procedure TryToUpdatePurchaseOrder(var PurchaseHeaderStaging: Record "EE Purch. Header Staging"; DocNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocNo);
        UpdatePurchaseOrder(PurchaseHeaderStaging, PurchaseHeader);
    end;

    [TryFunction]
    procedure TryToUpdatePurchaseOrder(var PurchaseHeaderStaging: Record "EE Purch. Header Staging"; var PurchaseHeader: Record "Purchase Header")
    begin
        UpdatePurchaseOrder(PurchaseHeaderStaging, PurchaseHeader);
    end;

    procedure UpdatePurchaseOrder(var PurchaseHeaderStaging: Record "EE Purch. Header Staging"; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        PurchLineStaging: Record "EE Purch. Line Staging";
        ClosedDate: Date;
        LineNo: Integer;
    begin
        GetAndCheckSetup();
        CheckPurchaseOrderSetup();
        GetVendorNo(PurchaseHeaderStaging);
        PurchaseHeader.SetHideValidationDialog(true);
        ClosedDate := DT2Date(PurchaseHeaderStaging.Closed);
        if ClosedDate <> 0D then
            PurchaseHeader.Validate("Posting Date", ClosedDate);
        if PurchaseHeaderStaging.invoice_number <> '' then
            if PurchaseHeaderStaging.invoice_number <> PurchaseHeader."Vendor Invoice No." then
                PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeaderStaging.invoice_number);
        PurchaseHeader.Modify(true);


        PurchaseHeaderStaging.Processed := true;
        if PurchaseHeaderStaging."Document No." <> PurchaseHeader."No." then
            PurchaseHeaderStaging.Validate("Document No.", PurchaseHeader."No.");
        PurchaseHeaderStaging.Modify(true);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindLast() then
            LineNo := PurchaseLine."Line No.";

        UpdateExtraPurchaseLines(PurchaseLine, PurchaseHeaderStaging, PurchaseHeader."No.", LineNo, GetTaxLineID(), PurchaseHeaderStaging.tax_total, 'Taxes');
        UpdateExtraPurchaseLines(PurchaseLine, PurchaseHeaderStaging, PurchaseHeader."No.", LineNo, GetShippingLineID(), PurchaseHeaderStaging.shipping_total, 'Shipping');
        UpdateExtraPurchaseLines(PurchaseLine, PurchaseHeaderStaging, PurchaseHeader."No.", LineNo, GetOtherLineID(), PurchaseHeaderStaging.other_total, 'Other Charges');

        PurchLineStaging.SetCurrentKey("Header Id", "Header Entry No.");
        PurchLineStaging.SetRange("Header Id", PurchaseHeaderStaging.id);
        PurchLineStaging.SetRange("Header Entry No.", PurchaseHeaderStaging."Entry No.");
        if not PurchLineStaging.FindSet() then
            exit;
        repeat
            PurchaseLine.SetRange("EE Part Id", PurchLineStaging.part_id);
            if not PurchaseLine.FindFirst() then begin
                LineNo += 10000;
                AddPurchaseLine(PurchaseLine, PurchLineStaging, PurchaseHeader."No.", LineNo);
            end else begin
                PurchaseLine."Qty. Rounding Precision" := 0;
                PurchaseLine."Qty. Rounding Precision (Base)" := 0;
                PurchaseLine.Validate(Quantity, PurchLineStaging.part_quantity);
                PurchaseLine.Validate("Unit Cost", PurchLineStaging.unit_price);
                PurchaseLine.Validate("Direct Unit Cost", PurchLineStaging.unit_price);
                PurchaseLine.Description := CopyStr(PurchLineStaging.part_description, 1, MaxStrLen(PurchaseLine.Description));
                PurchaseLine.Modify(true);
            end;
        until PurchLineStaging.Next() = 0;
        PurchaseLine.SetFilter("EE Part Id", '<>%1&<>%2&<>%3&<>%4', '', GetTaxLineID(), GetShippingLineID(), GetOtherLineID());
        if PurchaseLine.FindSet() then
            repeat
                PurchLineStaging.SetRange(part_id, PurchaseLine."EE Part Id");
                if PurchLineStaging.IsEmpty() then
                    PurchaseLine.Delete(true);
            until PurchaseLine.Next() = 0;
    end;


    local procedure GetShippingLineID(): Code[20]
    begin
        exit('shipping');
    end;

    local procedure GetTaxLineID(): Code[20]
    begin
        exit('tax');
    end;

    local procedure GetOtherLineID(): Code[20]
    begin
        exit('other');
    end;

    local procedure GetFeesLineID(): Code[20]
    begin
        exit('fees');
    end;


    local procedure UpdateExtraPurchaseLines(var PurchaseLine: Record "Purchase Line"; var PurchaseHeaderStaging: Record "EE Purch. Header Staging"; DocNo: Code[20]; var LineNo: Integer; LineID: Code[20]; Amount: Decimal; Descr: Text)
    begin
        PurchaseLine.SetRange("EE Part Id", LineID);
        if Amount <> 0 then begin
            if PurchaseLine.FindFirst() then begin
                PurchaseLine.Validate("Unit Cost", Amount);
                PurchaseLine.Validate("Direct Unit Cost", Amount);
                PurchaseLine.Modify(true);
            end else
                AddExtraPurchLine(LineNo, DocNo, Descr, Amount, LineID);
        end else
            if PurchaseLine.FindFirst() then
                PurchaseLine.Delete(true);
    end;

    local procedure AddPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchLineStaging: Record "EE Purch. Line Staging"; DocNo: Code[20]; LineNo: Integer)
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", Enum::"Purchase Document Type"::Order);
        PurchaseLine.Validate("Document No.", DocNo);
        PurchaseLine.Validate("Line No.", LineNo);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", FleetRockSetup."Purchase Item No.");
        PurchaseLine.Validate("Qty. Rounding Precision", 0);
        PurchaseLine.Validate("Qty. Rounding Precision (Base)", 0);
        PurchaseLine.Validate(Quantity, PurchLineStaging.part_quantity);
        PurchaseLine.Validate("Unit Cost", PurchLineStaging.unit_price);
        PurchaseLine.Validate("Direct Unit Cost", PurchLineStaging.unit_price);
        PurchaseLine.Description := CopyStr(PurchLineStaging.part_description, 1, MaxStrLen(PurchaseLine.Description));
        PurchaseLine.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
        PurchaseLine.Validate("Tax Group Code", FleetrockSetup."Non-Taxable Tax Group Code");
        PurchaseLine.Validate("EE Part Id", PurchLineStaging.part_id);
        PurchaseLine.Insert(true);
    end;



    procedure PopulateStagingTable(var RecVar: Variant; var OrderJsonObj: JsonObject; TableNo: Integer; StartFieldNo: Integer)
    begin
        PopulateStagingTable(RecVar, OrderJsonObj, TableNo, StartFieldNo, 99, false);
    end;

    procedure PopulateStagingTable(var RecVar: Variant; var OrderJsonObj: JsonObject; TableNo: Integer; StartFieldNo: Integer; EndFieldNo: Integer; ProcessIntegers: Boolean)
    var
        FieldRec: Record Field;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        FieldRec.SetRange(TableNo, TableNo);
        FieldRec.SetRange("No.", StartFieldNo, EndFieldNo);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Type, FieldRec.Type::Text);
        if FieldRec.FindSet() then
            repeat
                RecRef.Field(FieldRec."No.").Value(JsonMgt.GetJsonValueAsText(OrderJsonObj, FieldRec.FieldName));
            until FieldRec.Next() = 0;
        FieldRec.SetRange(Type, FieldRec.Type::Decimal);
        if FieldRec.FindSet() then
            repeat
                RecRef.Field(FieldRec."No.").Value(JsonMgt.GetJsonValueAsDecimal(OrderJsonObj, FieldRec.FieldName));
            until FieldRec.Next() = 0;
        if ProcessIntegers then begin
            FieldRec.SetRange(Type, FieldRec.Type::Integer);
            if FieldRec.FindSet() then
                repeat
                    RecRef.Field(FieldRec."No.").Value(JsonMgt.GetJsonValueAsInteger(OrderJsonObj, FieldRec.FieldName));
                until FieldRec.Next() = 0;
        end;
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
        CustLedgerEntry2.SetLoadFields("Closed by Entry No.", "Document Type", "Document No.", "Closed at Date");
        CustLedgerEntry2.SetCurrentKey("Closed by Entry No.");
        CustLedgerEntry2.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        SalesInvHeader.SetRange(Closed, true);
        SalesInvHeader.SetRange("Remaining Amount", 0);
        SalesInvHeader.SetFilter("EE Fleetrock ID", '<>%1', '');
        repeat
            CustLedgerEntry2.SetRange("Closed by Entry No.", CustLedgerEntry."Entry No.");
            if CustLedgerEntry2.FindFirst() then begin
                SalesInvHeader.SetRange("No.", CustLedgerEntry2."Document No.");
                if SalesInvHeader.FindFirst() then begin
                    if CustLedgerEntry2."Closed at Date" = Today() then
                        PaymentDateTime := CurrentDateTime()
                    else
                        PaymentDateTime := CreateDateTime(CustLedgerEntry2."Closed at Date", Time());
                    UpdatePaidRepairOrder(SalesInvHeader."EE Fleetrock ID", PaymentDateTime, SalesInvHeader);
                end;
            end;
        until CustLedgerEntry.Next() = 0;
    end;

    procedure UpdatePaidRepairOrder(OrderId: Text; PaidDateTime: DateTime; var SalesInvHeader: Record "Sales Invoice Header")
    var
        ResponseArray: JsonArray;
        JsonBody, ResponseObj : JsonObject;
        T: JsonToken;
        APIToken, URL, s : Text;
        Success: Boolean;
    begin
        if SalesInvHeader."EE Sent Payment" and (SalesInvHeader."EE Sent Payment DateTime" <> 0DT) then begin
            InsertImportEntry(false, 0, Enum::"EE Import Type"::"Repair Order", Enum::"EE Event Type"::Paid,
                Enum::"EE Direction"::Export, StrSubstNo('Invoice %1 already sent payment at %2', SalesInvHeader."No.", SalesInvHeader."EE Sent Payment DateTime"), URL, 'POST', JsonBody);
            exit;
        end;
        APIToken := CheckToGetAPIToken();
        URL := StrSubstNo('%1/API/UpdateRO?token=%2', FleetrockSetup."Integration URL", APIToken);
        JsonBody := CreateUpdateRepairOrderJsonBody(FleetrockSetup.Username, OrderId, PaidDateTime);
        if not RestAPIMgt.TryToGetResponseAsJsonArray(URL, 'response', 'POST', JsonBody, ResponseArray) then begin
            InsertImportEntry(false, 0, Enum::"EE Import Type"::"Repair Order", Enum::"EE Event Type"::Paid,
                Enum::"EE Direction"::Export, GetLastErrorText(), URL, 'POST', JsonBody);
            exit;
        end;
        if (ResponseArray.Count() = 0) then
            exit;
        if not ResponseArray.Get(0, T) then begin
            ResponseArray.WriteTo(s);
            InsertImportEntry(false, 0, Enum::"EE Import Type"::"Repair Order", Enum::"EE Event Type"::Paid,
               Enum::"EE Direction"::Export, 'Failed to load results token from response array: ' + s, URL, 'POST', JsonBody);
            exit;
        end;
        ClearLastError();
        Success := TryToHandleRepairUpdateResponse(T, OrderId);
        InsertImportEntry(Success and (GetLastErrorText() = ''), 0, Enum::"EE Import Type"::"Repair Order",
            Enum::"EE Event Type"::Paid, Enum::"EE Direction"::Export, GetLastErrorText(), URL, 'POST', JsonBody);
        SalesInvHeader."EE Sent Payment" := Success;
        SalesInvHeader."EE Sent Payment DateTime" := CurrentDateTime();
        SalesInvHeader.Modify(true);
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
        if T.AsValue().AsText() <> 'success' then
            Error('Failed to update Repair Order %1:\%2', OrderId, JsonMgt.GetJsonValueAsText(ResponseObj, 'message'));
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





    procedure InsertImportEntry(Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type"; Direction: Enum "EE Direction"; ErrorMsg: Text; URL: Text; Method: Text)
    var
        JsonBody: JsonObject;
        EntryNo: Integer;
    begin
        InsertImportEntry(EntryNo, Success, ImportEntryNo, Type, EventType, Direction, ErrorMsg, URL, Method, JsonBody);
    end;

    procedure InsertImportEntry(Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type"; Direction: Enum "EE Direction"; ErrorMsg: Text; URL: Text; Method: Text; var JsonBody: JsonObject)
    var
        EntryNo: Integer;
    begin
        InsertImportEntry(EntryNo, Success, ImportEntryNo, Type, EventType, Direction, ErrorMsg, URL, Method, JsonBody);
    end;


    // procedure InsertImportEntry(var EntryNo: Integer; Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type"; Direction: Enum "EE Direction"; ErrorMsg: Text; URL: Text; Method: Text)
    // var
    //     JsonBody: JsonObject;
    // begin
    //     InsertImportEntry(EntryNo, Success, ImportEntryNo, Type, EventType, Direction, ErrorMsg, URL, Method, JsonBody);
    // end;

    procedure InsertImportEntry(var EntryNo: Integer; Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type"; Direction: Enum "EE Direction"; ErrorMsg: Text; URL: Text; Method: Text; var JsonBody: JsonObject)
    var
        ImportEntry: Record "EE Import/Export Entry";
        PurchHeaderStaging: Record "EE Purch. Header Staging";
        SalesHeaderStaging: Record "EE Sales Header Staging";
        s: Text;
        DocNo: Code[20];
    begin
        if ImportEntryNo <> 0 then begin
            PurchHeaderStaging.SetLoadFields("Entry No.", "Document No.");
            SalesHeaderStaging.SetLoadFields("Entry No.", "Document No.");
            case Type of
                Type::"Purchase Order":
                    if PurchHeaderStaging.Get(ImportEntryNo) then
                        DocNo := PurchHeaderStaging."Document No.";
                Type::"Repair Order":
                    if SalesHeaderStaging.Get(ImportEntryNo) then
                        DocNo := SalesHeaderStaging."Document No.";
            end;
        end;
        ErrorMsg := CopyStr(ErrorMsg, 1, MaxStrLen(ImportEntry."Error Message"));
        if (ErrorMsg <> '') then begin
            ImportEntry.SetRange(Direction, Direction);
            ImportEntry.SetRange("Document Type", Type);
            ImportEntry.SetFilter("Document No.", DocNo);
            ImportEntry.SetRange("Event Type", EventType);
            ImportEntry.SetRange("Error Message", ErrorMsg);
            if not ImportEntry.IsEmpty() then begin
                if PurchHeaderStaging."Entry No." <> 0 then
                    PurchHeaderStaging.Delete(true);
                if SalesHeaderStaging."Entry No." <> 0 then
                    SalesHeaderStaging.Delete(true);
                exit;
            end;
        end;

        JsonBody.WriteTo(s);
        ImportEntry.Reset();
        ImportEntry.LockTable();
        if ImportEntry.FindLast() then
            EntryNo := ImportEntry."Entry No.";
        EntryNo += 1;
        ImportEntry.Init();
        ImportEntry."Entry No." := EntryNo;
        ImportEntry."Document Type" := Type;
        ImportEntry.Success := Success;
        ImportEntry."Error Message" := ErrorMsg;
        ImportEntry."Error Stack" := CopyStr(GetLastErrorCallStack(), 1, MaxStrLen(ImportEntry."Error Stack"));
        ImportEntry."Import Entry No." := ImportEntryNo;
        if DocNo <> '' then
            ImportEntry."Document No." := DocNo;
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
        JsonMgt: Codeunit "EE Json Mgt.";
}