codeunit 80000 "EE Fleetrock Mgt."
{
    Permissions = tabledata "EE Fleetrock Setup" = RIMD,
    tabledata "EE Purch. Header Staging" = RIMD,
    tabledata "EE Purch. Line Staging" = RIMD,
    tabledata "EE Import/Export Entry" = RIMD,
    tabledata "EE Sales Header Staging" = RIMD,
    tabledata "EE Task Line Staging" = RIMD,
    tabledata "EE Part Line Staging" = RIMD,
    tabledata "Purchase Header" = RIMD,
    tabledata "Purchase Line" = RIMD,
    tabledata "Sales Header" = RIMD,
    tabledata "Sales Line" = RIMD,
    tabledata "Vendor" = RIMD,
    tabledata "Payment Terms" = RIMD,
    tabledata "G/L Account" = RIMD,
    tabledata "Purch. Inv. Header" = RM,
    tabledata "Purch. Inv. Line" = RM,
    tabledata "Sales Invoice Header" = RM,
    tabledata "Sales Invoice Line" = RM,
    tabledata "EE Claim Header" = RIMD,
    tabledata "EE Claim Line" = RIMD;



    local procedure GetAndCheckSetup()
    begin
        GetAndCheckSetup(false);
    end;

    local procedure GetAndCheckSetup(UseVendorKey: Boolean)
    begin
        if UseVendorKey then begin
            if LoadedVendorSetup then
                exit
        end else if LoadedSetup then
                exit;
        FleetrockSetup.Get();
        FleetrockSetup.TestField("Integration URL");
        if UseVendorKey then begin
            FleetrockSetup.TestField("Vendor Username");
            FleetrockSetup.TestField("Vendor API Key");
            LoadedVendorSetup := true;
        end else begin
            FleetrockSetup.TestField("Username");
            FleetrockSetup.TestField("API Key");
            LoadedSetup := true;
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



    procedure CheckPurchaseOrderSetup()
    begin
        GetAndCheckSetup();
        CheckPurchaseOrderSetup(FleetrockSetup);
    end;

    procedure CheckPurchaseOrderSetup(var FleetrockSetup: Record "EE Fleetrock Setup")
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
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        VendorNo, RemitVendorNo : Code[20];
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
        if PurchHeaderStaging.Closed <> 0DT then
            PurchaseHeader.Validate("Posting Date", DT2Date(PurchHeaderStaging.Closed))
        else
            PurchaseHeader.Validate("Posting Date", DT2Date(PurchHeaderStaging.Received));
        PurchaseHeader.Validate("Document Date", PurchaseHeader."Posting Date");
        PurchaseHeader.Insert(true);
        DocNo := PurchaseHeader."No.";

        ClearLastError();
        if not TryToGetVendorNo(PurchHeaderStaging, VendorNo, false) then begin
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

        if PurchHeaderStaging.remit_to <> '' then begin
            ClearLastError();
            if not TryToGetVendorNo(PurchHeaderStaging, RemitVendorNo, true) then begin
                if Vendor.Get(RemitVendorNo) then
                    Vendor.Delete(true);
                Error(GetLastErrorText());
            end else
                PurchaseHeader.Validate("Pay-to Vendor No.", RemitVendorNo);
        end;

        if PurchHeaderStaging.invoice_number <> '' then
            SetVendorInvoiceNo(PurchaseHeader, PurchHeaderStaging.invoice_number);

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
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("EE Fleetrock ID", CopyStr(ImportId, 1, MaxStrLen(SalesHeader."EE Fleetrock ID")));
        if SalesHeader.FindFirst() then
            Error('Fleetrock Sales Order %1 has already been imported as order %2.', ImportId, SalesHeader."No.");
        CheckIfSalesInvAlreadyImported(ImportId, true);
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
        if ImportId = '' then
            exit(false);
        CheckIfPurchaseInvAlreadyImported(ImportId, true);
        PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("EE Fleetrock ID", ImportId);
        if PurchaseHeader.FindFirst() then;
    end;





    procedure CheckIfSalesInvAlreadyImported(ImportId: Text; ThrowError: Boolean): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        if ImportId = '' then
            exit(false);
        SalesInvHeader.SetCurrentKey("EE Fleetrock ID");
        SalesInvHeader.SetRange("EE Fleetrock ID", CopyStr(ImportId, 1, MaxStrLen(SalesInvHeader."EE Fleetrock ID")));
        SalesInvHeader.SetRange(Cancelled, false);
        SalesInvHeader.SetFilter(Amount, '<>%1', 0);
        if SalesInvHeader.FindFirst() then
            if ThrowError then
                Error('Fleetrock Sales Order %1 has already been imported as order %2, and posted as invoice %3.', ImportId, SalesInvHeader."Order No.", SalesInvHeader."No.")
            else
                exit(true);
        exit(false);
    end;

    procedure CheckIfPurchaseInvAlreadyImported(ImportId: Text; ThrowError: Boolean): Boolean
    var
        PurchaseInvHeader: Record "Purch. Inv. Header";
    begin
        if ImportId = '' then
            exit(false);
        PurchaseInvHeader.SetCurrentKey("EE Fleetrock ID");
        PurchaseInvHeader.SetRange("EE Fleetrock ID", CopyStr(ImportId, 1, MaxStrLen(PurchaseInvHeader."EE Fleetrock ID")));
        PurchaseInvHeader.SetRange(Cancelled, false);
        PurchaseInvHeader.SetFilter(Amount, '<>%1', 0);
        if PurchaseInvHeader.FindFirst() then
            if ThrowError then
                Error('Fleetrock Purchase Order %1 has already been imported as order %2, and posted as invoice %3.', ImportId, PurchaseInvHeader."Order No.", PurchaseInvHeader."No.")
            else
                exit(true);
        exit(false);
    end;







    [TryFunction]
    local procedure TryToGetVendorNo(var PurchHeaderStaging: Record "EE Purch. Header Staging"; var VendorNo: Code[20]; RemitTo: Boolean)
    begin
        VendorNo := GetVendorNo(PurchHeaderStaging, RemitTo);
    end;

    local procedure GetVendorNo(var PurchHeaderStaging: Record "EE Purch. Header Staging"; RemitTo: Boolean): Code[20]
    var
        VendorNo: Code[20];
    begin
        SingleInstance.SetSkipVendorUpdate(true);
        VendorNo := GetVendorNoAndUpdate(PurchHeaderStaging, RemitTo);
        SingleInstance.SetSkipVendorUpdate(false);
        exit(VendorNo);
    end;




    local procedure GetVendorNoAndUpdate(SupplierName: Text): Code[20]
    var
        PurchHeaderStaging: Record "EE Purch. Header Staging";
    begin
        if SupplierName = '' then
            Error('supplier_name must be specified.');
        if FleetrockSetup."Import Vendor Details" then
            Error('Cannot get vendor details without related Purchase Staging Header if Vendor insert is enabled.\%1', SupplierName);
        exit(GetVendorNoAndUpdate(PurchHeaderStaging, SupplierName, false, false));
    end;

    local procedure GetVendorNoAndUpdate(var PurchHeaderStaging: Record "EE Purch. Header Staging"; RemitTo: Boolean): Code[20]
    var
        VendorName: Text;
    begin
        if RemitTo then begin
            if PurchHeaderStaging.remit_to = '' then
                Error('remit_to must be specified.');
            VendorName := PurchHeaderStaging.remit_to;
        end else begin
            if PurchHeaderStaging.supplier_name = '' then
                Error('supplier_name must be specified.');
            VendorName := PurchHeaderStaging.supplier_name;
        end;
        exit(GetVendorNoAndUpdate(PurchHeaderStaging, VendorName, true, RemitTo));
    end;

    local procedure GetVendorNoAndUpdate(var PurchHeaderStaging: Record "EE Purch. Header Staging"; SupplierName: Text; ThrowError: Boolean; RemitTo: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        VendorObj: JsonObject;
        MissingSource, Update : Boolean;
    begin
        Vendor.SetRange("EE Source Type", Vendor."EE Source Type"::Fleetrock);
        Vendor.SetRange("EE Source No.", SupplierName);
        if Vendor.IsEmpty() then begin
            Vendor.Reset();
            Vendor.SetRange(Name, SupplierName);
            MissingSource := true;
        end;
        if Vendor.FindFirst() then begin
            Update := UpdateVendor(Vendor, SupplierName, RemitTo);
            if Vendor."Tax Area Code" = '' then begin
                Vendor.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
                Update := true;
            end;
            if MissingSource then begin
                Vendor.Validate("EE Source Type", Vendor."EE Source Type"::Fleetrock);
                Vendor.Validate("EE Source No.", SupplierName);
                Update := true;
            end;
            if Update then
                Vendor.Modify(true);
            exit(Vendor."No.");
        end;

        GetAndCheckSetup();
        if not FleetrockSetup."Import Vendor Details" then
            if ThrowError then
                Error('Vendor %1 not found.', SupplierName)
            else
                exit('');

        InitVendor(PurchHeaderStaging, Vendor, SupplierName);
        UpdateVendor(Vendor, SupplierName, RemitTo);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;


    procedure UpdateVendor(var Vendor: Record Vendor; SupplierName: Text; RemitTo: Boolean): Boolean
    var
        VendorObj: JsonObject;
    begin
        if GetVendorDetails(SupplierName, VendorObj, RemitTo) then
            exit(UpdateVendorFromJson(Vendor, VendorObj));
    end;


    local procedure UpdateVendorFromJson(var Vendor: Record Vendor; var VendorObj: JsonObject): Boolean
    var
        Vendor2: Record Vendor;
        PaymentTermsCode: Code[10];
        PhoneNo, Input : Text;
        PaymentTermDays: Integer;
    begin
        Vendor2 := Vendor;

        Input := CopyStr(JsonMgt.GetJsonValueAsText(VendorObj, 'street_address_1'), 1, MaxStrLen(Vendor.Address));
        if Input <> '' then
            if Vendor.Address = '' then
                Vendor.Validate(Address, Input);
        Input := CopyStr(JsonMgt.GetJsonValueAsText(VendorObj, 'street_address_2'), 1, MaxStrLen(Vendor."Address 2"));
        if Input <> '' then
            if Vendor."Address 2" = '' then
                Vendor.Validate("Address 2", Input);
        Input := CopyStr(JsonMgt.GetJsonValueAsText(VendorObj, 'city'), 1, MaxStrLen(Vendor."City"));
        if Input <> '' then
            if Vendor."City" = '' then
                Vendor.Validate("City", Input);
        Input := CopyStr(JsonMgt.GetJsonValueAsText(VendorObj, 'state'), 1, MaxStrLen(Vendor.County));
        if Input <> '' then
            if Vendor."County" = '' then
                Vendor.Validate(County, Input);
        Input := CopyStr(JsonMgt.GetJsonValueAsText(VendorObj, 'country'), 1, MaxStrLen(Vendor."Country/Region Code"));
        if Input <> '' then
            if Vendor."Country/Region Code" = '' then
                Vendor."Country/Region Code" := Input;
        Input := CopyStr(JsonMgt.GetJsonValueAsText(VendorObj, 'zip_code'), 1, MaxStrLen(Vendor."Post Code"));
        if Input <> '' then
            if Vendor."Post Code" = '' then
                Vendor.Validate("Post Code", Input);
        Input := CopyStr(JsonMgt.GetJsonValueAsText(VendorObj, 'email'), 1, MaxStrLen(Vendor."E-Mail"));
        if Input <> '' then
            if Vendor."E-Mail" = '' then
                Vendor.Validate("E-Mail", Input);

        PhoneNo := CopyStr(JsonMgt.GetJsonValueAsText(VendorObj, 'phone'), 1, MaxStrLen(Vendor."Phone No."));
        if (PhoneNo <> '') and (Vendor."Phone No." = '') then
            if not TryToSetVendorNo(Vendor, PhoneNo) then
                Vendor."Phone No." := PhoneNo;
        PaymentTermDays := Round(JsonMgt.GetJsonValueAsDecimal(VendorObj, 'payment_term_days'), 1);
        if PaymentTermDays = 0 then
            PaymentTermsCode := FleetrockSetup."Payment Terms"
        else
            PaymentTermsCode := GetPaymentTerms(PaymentTermDays);
        if Vendor."Payment Terms Code" = '' then
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

    local procedure InitVendor(var PurchHeaderStaging: Record "EE Purch. Header Staging"; var Vendor: Record Vendor; VendorName: Text)
    begin
        PurchHeaderStaging.TestField("Entry No.");
        Vendor.Init();
        Vendor.Insert(true);
        Vendor.Validate(Name, VendorName);
        Vendor.Validate("EE Source Type", Vendor."EE Source Type"::Fleetrock);
        Vendor.Validate("EE Source No.", VendorName);
        Vendor.Validate("Vendor Posting Group", FleetrockSetup."Vendor Posting Group");
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
    end;




    local procedure GetVendorDetails(SupplierName: Text; var VendorObj: JsonObject; RemitTo: Boolean): Boolean
    var
        VendorArray: JsonArray;
        T: JsonToken;
    begin
        if RemitTo then
            exit(GetVendorAsUserDetails(SupplierName, VendorObj, true));
        CheckToGetAPIToken();
        VendorArray := RestAPIMgt.GetResponseAsJsonArray(StrSubstNo('%1/API/GetSuppliers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, CheckToGetAPIToken()), 'suppliers');
        foreach T in VendorArray do begin
            VendorObj := T.AsObject();
            if JsonMgt.GetJsonValueAsText(VendorObj, 'name') = SupplierName then
                exit(true);
        end;
        if GetVendorAsUserDetails(SupplierName, VendorObj, false) then
            exit(true);
        exit(GetVendorAsUserDetails(SupplierName, VendorObj, true));
    end;

    local procedure GetVendorAsUserDetails(SupplierName: Text; RemitTo: Boolean): Boolean
    var
        VendorObj: JsonObject;
    begin
        exit(GetVendorAsUserDetails(SupplierName, VendorObj, RemitTo));
    end;

    local procedure GetVendorAsUserDetails(SupplierName: Text; var VendorObj: JsonObject; RemitTo: Boolean): Boolean
    var
        VendorArray: JsonArray;
        T: JsonToken;
    begin
        CheckToGetAPIToken();
        VendorArray := RestAPIMgt.GetResponseAsJsonArray(StrSubstNo('%1/API/GetUsers?username=%2&token=%3', FleetrockSetup."Integration URL", FleetrockSetup.Username, CheckToGetAPIToken()), 'users');
        foreach T in VendorArray do begin
            VendorObj := T.AsObject();
            if JsonMgt.GetJsonValueAsText(VendorObj, 'role') = 'vendor' then
                if RemitTo then begin
                    if JsonMgt.GetJsonValueAsText(VendorObj, 'company_name') = SupplierName then
                        exit(true)
                end else
                    if JsonMgt.GetJsonValueAsText(VendorObj, 'username') = SupplierName then
                        exit(true);
        end;
    end;


    procedure SendVendorDetails(var Vendor: Record Vendor; EventType: Enum "EE Event Type"): Boolean
    var
        ResponseArray: JsonArray;
        JsonBody, VendorJson : JsonObject;
        JTkn: JsonToken;
        URL, APIToken, s : Text;
        Success: Boolean;
    begin
        APIToken := CheckToGetAPIToken();
        URL := StrSubstNo('%1/API/AddUser?token=%2', FleetrockSetup."Integration URL", APIToken);
        if not TryToCreateAddUserJsonBody(Vendor, FleetrockSetup.Username, JsonBody) then begin
            InsertImportEntry(false, 0, Enum::"EE Import Type"::Vendor, EventType, Enum::"EE Direction"::Export,
                GetLastErrorText(), URL, 'POST', JsonBody, Vendor."No.");
            exit(false);
        end;

        if GetVendorAsUserDetails(Vendor."No.", false) then
            URL := StrSubstNo('%1/API/UpdateUser?token=%2', FleetrockSetup."Integration URL", APIToken);
        if not RestAPIMgt.TryToGetResponseAsJsonArray(URL, 'response', 'POST', JsonBody, ResponseArray) then begin
            InsertImportEntry(false, 0, Enum::"EE Import Type"::Vendor, EventType, Enum::"EE Direction"::Export,
                GetLastErrorText(), URL, 'POST', JsonBody, Vendor."No.");
            exit(false);
        end;
        if (ResponseArray.Count() = 0) then
            exit;
        if not ResponseArray.Get(0, JTkn) then begin
            ResponseArray.WriteTo(s);
            InsertImportEntry(false, 0, Enum::"EE Import Type"::Vendor, EventType, Enum::"EE Direction"::Export,
                'Failed to load results token from response array: ' + s, URL, 'POST', JsonBody, Vendor."No.");
            exit(false);
        end;
        ClearLastError();
        Success := TryToHandleRepairUpdateResponse(JTkn, Vendor."No.", StrSubstNo('Failed to %1 User ', EventType) + '%1:\%2');
        InsertImportEntry(Success and (GetLastErrorText() = ''), 0, Enum::"EE Import Type"::Vendor, EventType,
            Enum::"EE Direction"::Export, GetLastErrorText(), URL, 'POST', JsonBody, Vendor."No.");
        exit(Success);
    end;


    [TryFunction]
    local procedure TryToCreateAddUserJsonBody(var Vendor: Record Vendor; Username: Text; var JsonBody: JsonObject)
    begin
        JsonBody := CreateAddUserJsonBody(Vendor, Username);
    end;

    local procedure CreateAddUserJsonBody(var Vendor: Record Vendor; Username: Text): JsonObject
    var
        JsonBody, UserObj : JsonObject;
        UserArray: JsonArray;
        Parts: List of [Text];
    begin
        Vendor.TestField("No.");
        Vendor.TestField(Name);
        Vendor.TestField("E-Mail");

        UserObj.Add('username', Vendor."No.");
        UserObj.Add('custom_id', Vendor."No.");
        UserObj.Add('role', 'vendor');
        UserObj.Add('email', Vendor."E-Mail");
        UserObj.Add('first_name', Vendor.Name);
        UserObj.Add('last_name', Vendor.Name);
        UserObj.Add('company_name', Vendor.Name);
        if Vendor."EE Source No." <> '' then
            UserObj.Add('company_id', Vendor."EE Source No.");
        if Vendor.Address <> '' then
            UserObj.Add('street_address', Vendor.Address);
        if Vendor.City <> '' then
            UserObj.Add('city', Vendor."City");
        if Vendor.County <> '' then
            UserObj.Add('state', Vendor."County");
        if Vendor."Post Code" <> '' then
            UserObj.Add('zip_code', Vendor."Post Code");
        case Vendor."Country/Region Code" of
            'US', 'CA':
                UserObj.Add('country', Vendor."Country/Region Code");
        end;
        if Vendor."Phone No." <> '' then
            UserObj.Add('phone', Vendor."Phone No.");
        UserArray.Add(UserObj);
        JsonBody.Add('username', UserName);
        JsonBody.Add('users', UserArray);
        exit(JsonBody);
    end;


    [TryFunction]
    local procedure TryToGetCustomerNo(var SalesHeaderStaging: Record "EE Sales Header Staging"; var CustomerNo: Code[20]; RemitTo: Boolean)
    begin
        CustomerNo := GetCustomerNo(SalesHeaderStaging, RemitTo);
    end;

    local procedure GetCustomerNo(var SalesHeaderStaging: Record "EE Sales Header Staging"; RemitTo: Boolean): Code[20]
    var
        Customer: Record Customer;
        CustomerObj: JsonObject;
        T: JsonToken;
        SourceNo: Text;
        PaymentTermDays: Integer;
        IsSourceCompany: Boolean;
    begin
        if RemitTo then
            if SalesHeaderStaging.remit_to_company_id <> '' then
                SourceNo := SalesHeaderStaging.remit_to_company_id
            else
                if SalesHeaderStaging.remit_to <> '' then begin
                    SourceNo := SalesHeaderStaging.remit_to;
                    IsSourceCompany := true;
                end else
                    Error('remit_to or remit_to_company_id must be specified.')
        else
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
            InitCustomer(SalesHeaderStaging, Customer, SourceNo, RemitTo);
            Customer.Modify(true);
            exit(Customer."No.");
        end;

        InitCustomer(SalesHeaderStaging, Customer, SourceNo, RemitTo);
        if GetCustomerDetails(SourceNo, IsSourceCompany, CustomerObj) then
            UpdateCustomerFromJson(Customer, CustomerObj);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure UpdateCustomerFromJson(var Customer: Record Customer; var CustomerObj: JsonObject): Boolean
    var
        Customer2: Record Customer;
        PhoneNo, Input : Text;
        PaymentTermsCode: Code[10];
        PaymentTermDays: Integer;
    begin
        Customer2 := Customer;
        Input := CopyStr(JsonMgt.GetJsonValueAsText(CustomerObj, 'street_address_1'), 1, MaxStrLen(Customer.Address));
        if Customer.Address <> Input then
            Customer.Validate(Address, Input);
        Input := CopyStr(JsonMgt.GetJsonValueAsText(CustomerObj, 'street_address_2'), 1, MaxStrLen(Customer."Address 2"));
        if Customer."Address 2" <> Input then
            Customer.Validate("Address 2", Input);
        Input := CopyStr(JsonMgt.GetJsonValueAsText(CustomerObj, 'city'), 1, MaxStrLen(Customer."City"));
        if Customer."City" <> Input then
            Customer.Validate("City", Input);
        Input := CopyStr(JsonMgt.GetJsonValueAsText(CustomerObj, 'state'), 1, MaxStrLen(Customer.County));
        if Customer."County" <> Input then
            Customer.Validate(County, Input);
        Input := CopyStr(JsonMgt.GetJsonValueAsText(CustomerObj, 'country'), 1, MaxStrLen(Customer."Country/Region Code"));
        if Customer."Country/Region Code" <> Input then
            Customer."Country/Region Code" := Input;
        Input := CopyStr(JsonMgt.GetJsonValueAsText(CustomerObj, 'zip_code'), 1, MaxStrLen(Customer."Post Code"));
        if Customer."Post Code" <> Input then
            Customer.Validate("Post Code", Input);

        PhoneNo := CopyStr(JsonMgt.GetJsonValueAsText(CustomerObj, 'phone'), 1, MaxStrLen(Customer."Phone No."));
        if not TryToSetCustomerPhoneNo(Customer, PhoneNo) then
            Customer."Phone No." := PhoneNo;

        Input := CopyStr(JsonMgt.GetJsonValueAsText(CustomerObj, 'company_name'), 1, MaxStrLen(Customer.Name));
        if Input <> '' then
            if Customer."Name" <> Input then
                Customer.Validate("Name", Input);
        Input := CopyStr(StrSubstNo('%1 %2', JsonMgt.GetJsonValueAsText(CustomerObj, 'first_name'), JsonMgt.GetJsonValueAsText(CustomerObj, 'last_name')).Trim(), 1, MaxStrLen(Customer."Name 2"));
        if Input <> '' then
            if Customer."Name 2" <> Input then
                Customer.Validate("Name 2", Input);


        exit((Customer.Address <> Customer2.Address)
            or (Customer2."City" <> Customer."City")
            or (Customer2."County" <> Customer."County")
            or (Customer2."Country/Region Code" <> Customer."Country/Region Code")
            or (Customer2."Post Code" <> Customer."Post Code")
            or (Customer2."Phone No." <> Customer."Phone No.")
            or (Customer2.Name <> Customer.Name)
            or (Customer2."Name 2" <> Customer."Name 2"));
    end;



    [TryFunction]
    local procedure TryToSetCustomerPhoneNo(var Customer: Record Customer; PhoneNo: Text)
    begin
        Customer.Validate("Phone No.", PhoneNo);
    end;

    local procedure InitCustomer(var SalesHeaderStaging: Record "EE Sales Header Staging"; var Customer: Record Customer; SourceNo: Text; RemitTo: Boolean)
    begin
        Customer.Init();
        Customer.Insert(true);
        if RemitTo or (SalesHeaderStaging.customer_name = '') then
            Customer.Validate(Name, SourceNo)
        else
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
            if JsonMgt.GetJsonValueAsText(CustomerObj, SourceType) = SourceValue then
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
        Evaluate(DateFoRM, StrSubstNo('<%1D>', PaymentTermsDays));
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
        PurchHeaderStaging.LockTable(true);
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

        PurchLineStaging.LockTable(true);
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

    procedure GetAndImportPurchaseOrder(DocId: Text)
    var
        GetPurchOrdersCU: Codeunit "EE Get Purchase Orders";
        JsonArray, JsonArray2 : JsonArray;
        JTkn: JsonToken;
        JObjt: JsonObject;
        APIToken, URL : Text;
    begin
        APIToken := CheckToGetAPIToken();
        URL := StrSubstNo('%1/API/GetPO?username=%2&id=%3&token=%4', FleetrockSetup."Integration URL", FleetrockSetup.Username, DocId, APIToken);
        JsonArray := RestAPIMgt.GetResponseAsJsonArray(URL, 'purchase_orders');
        foreach JTkn in JsonArray do begin
            JObjt := JTkn.AsObject();
            if JsonMgt.GetJsonValueAsText(JObjt, 'id') = DocId then begin
                JsonArray2.Add(JObjt);
                GetPurchOrdersCU.ImportPurchaseOrders(JsonArray2, Enum::"EE Event Type"::"Manual Import", URL, false);
                exit;
            end;
        end;

        Error('Purchase Order with ID "%1" not found.', DocId);
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
        if URL = '' then begin
            GetEventParameters(APIToken, StartDateTime, EndDateTime, false);
            URL := StrSubstNo('%1/API/GetPO?username=%2&event=%3&token=%4&start=%5&end=%6', FleetrockSetup."Integration URL",
                FleetrockSetup.Username, EventType, APIToken, Format(StartDateTime, 0, 9), Format(EndDateTime, 0, 9));
        end;
        exit(RestAPIMgt.GetResponseAsJsonArray(URL, 'purchase_orders'));
    end;








    [TryFunction]
    procedure TryToGetRepairOrders(StartDateTime: DateTime; Status: Enum "EE Repair Order Status"; var RepairOrdersJsonArray: JsonArray; var URL: Text; UseVendorcAccount: Boolean)
    begin
        RepairOrdersJsonArray := GetRepairOrders(StartDateTime, Status, URL, UseVendorcAccount);
    end;

    procedure GetRepairOrders(StartDateTime: DateTime; Status: Enum "EE Repair Order Status"; var URL: Text; UseVendorcAccount: Boolean): JsonArray
    var
        APIToken: Text;
        EndDateTime: DateTime;
    begin
        GetEventParameters(APIToken, StartDateTime, EndDateTime, UseVendorcAccount);
        if UseVendorcAccount then
            URL := StrSubstNo('%1/API/GetRO?username=%2&event=%3&token=%4&start=%5&end=%6', FleetrockSetup."Integration URL",
                FleetrockSetup."Vendor Username", Status, APIToken, Format(StartDateTime, 0, 9), Format(EndDateTime, 0, 9))
        else
            URL := StrSubstNo('%1/API/GetRO?username=%2&event=%3&token=%4&start=%5&end=%6', FleetrockSetup."Integration URL",
                   FleetrockSetup.Username, Status, APIToken, Format(StartDateTime, 0, 9), Format(EndDateTime, 0, 9));
        exit(RestAPIMgt.GetResponseAsJsonArray(URL, 'repair_orders'));
    end;

    procedure GetAndImportRepairOrder(ID: Text; UseVendorcAccount: Boolean)
    var
        GetRepairOrdersCU: Codeunit "EE Get Repair Orders";
        JsonArray, JsonArray2 : JsonArray;
        JTkn: JsonToken;
        JObjt: JsonObject;
        StartDateTime, EndDateTime : DateTime;
        APIToken, URL : Text;
    begin
        StartDateTime := CurrentDateTime();
        GetEventParameters(APIToken, StartDateTime, EndDateTime, UseVendorcAccount);
        if UseVendorcAccount then
            URL := StrSubstNo('%1/API/GetRO?username=%2&ID=%3&token=%4', FleetrockSetup."Integration URL", FleetrockSetup."Vendor Username", ID, APIToken)
        else
            URL := StrSubstNo('%1/API/GetRO?username=%2&ID=%3&token=%4', FleetrockSetup."Integration URL", FleetrockSetup.Username, ID, APIToken);
        JsonArray := RestAPIMgt.GetResponseAsJsonArray(URL, 'repair_orders');

        foreach JTkn in JsonArray do begin
            JObjt := JTkn.AsObject();
            if JsonMgt.GetJsonValueAsText(JObjt, 'id') = ID then begin
                JsonArray2.Add(JObjt);
                if not GetRepairOrdersCU.IsValidToImport(JObjt) then
                    if not Confirm('Order %1 has been found but is not from an internal customer. Do you want to continue?', false, ID) then
                        exit;
                GetRepairOrdersCU.ImportRepairOrders(JsonArray2, Enum::"EE Repair Order Status"::Invoiced, Enum::"EE Event Type"::"Manual Import", URL);
                exit;
            end;
        end;

        Error('Repair Order with ID "%1" not found.', ID);
    end;



    local procedure GetEventParameters(var APIToken: Text; var StartDateTime: DateTime; var EndDateTime: DateTime; UseVendorKey: Boolean)
    begin
        APIToken := CheckToGetAPIToken(UseVendorKey);
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
        SalesHeaderStaging.LockTable(true);
        if SalesHeaderStaging.FindLast() then
            EntryNo := SalesHeaderStaging."Entry No.";
        EntryNo += 1;
        SalesHeaderStaging.Init();
        SalesHeaderStaging."Entry No." := EntryNo;
        RecVar := SalesHeaderStaging;

        PopulateStagingTable(RecVar, OrderJsonObj, Database::"EE Sales Header Staging", SalesHeaderStaging.FieldNo(id));
        SalesHeaderStaging := RecVar;
        SalesHeaderStaging."Internal Customer" := IsValidCustomer(SalesHeaderStaging.customer_name);
        SalesHeaderStaging.Insert(true);

        if not OrderJsonObj.Get('tasks', T) then
            exit;
        TaskLines := T.AsArray();
        if TaskLines.Count() = 0 then
            exit;
        TaskLineStaging.LockTable(true);
        if TaskLineStaging.FindLast() then
            LineEntryNo := TaskLineStaging."Entry No."
        else
            LineEntryNo := 0;
        PartLineStaging.LockTable(true);
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



    procedure IsValidCustomer(CustomerName: Text): Boolean;
    begin
        if CustomerName = '' then
            exit(false);
        GetAndCheckSetup();
        if FleetrockSetup."Valid Customer Names" = '' then
            exit(true);
        exit(CheckListForName(FleetrockSetup."Valid Customer Names", CustomerName));
    end;


    procedure IsValidVendor(VendorName: Text): Boolean;
    begin
        if VendorName = '' then
            exit(false);
        GetAndCheckSetup();
        if FleetrockSetup."Valid Vendor Names" = '' then
            exit(true);
        exit(CheckListForName(FleetrockSetup."Valid Vendor Names", VendorName));
    end;

    local procedure CheckListForName(InternalNames: Text; OrderName: Text): Boolean
    var
        CustomerNames: List of [Text];
    begin
        CustomerNames := InternalNames.Split('|');
        exit(CustomerNames.Contains(OrderName));
    end;


    procedure CheckRepairOrderSetup()
    begin
        GetAndCheckSetup();
        CheckRepairOrderSetup(FleetrockSetup);
    end;

    procedure CheckRepairOrderSetup(var FleetrockSetup: Record "EE Fleetrock Setup")
    begin
        FleetrockSetup.TestField("External Labor Item No.");
        FleetrockSetup.TestField("External Parts Item No.");
        if FleetrockSetup."Valid Customer Names" <> '' then begin
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
        if SalesHeaderStaging."Expected Finish At" <> 0DT then
            SalesHeader.Validate("Posting Date", DT2Date(SalesHeaderStaging."Expected Finish At"))
        else
            SalesHeader.Validate("Posting Date", DT2Date(SalesHeaderStaging."Started At"));
        SalesHeader.Insert(true);
        DocNo := SalesHeader."No.";

        ClearLastError();
        if not TryToGetCustomerNo(SalesHeaderStaging, CustomerNo, false) then begin
            if Customer.Get(CustomerNo) then
                Customer.Delete(true);
            Error(GetLastErrorText());
        end;
        Customer.Get(CustomerNo);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        if SalesHeaderStaging.remit_to <> '' then begin
            ClearLastError();
            if not TryToGetCustomerNo(SalesHeaderStaging, CustomerNo, true) then begin
                if Customer.Get(CustomerNo) then
                    Customer.Delete(true);
                Error(GetLastErrorText());
            end;
            Customer.Get(CustomerNo);
            SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        end;

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
        GetCustomerNo(SalesHeaderStaging, false);
        if SalesHeaderStaging.remit_to <> '' then
            GetCustomerNo(SalesHeaderStaging, true);
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
        RemitVendorNo: Code[20];
        LineNo: Integer;
    begin
        GetAndCheckSetup();
        CheckPurchaseOrderSetup();
        GetVendorNo(PurchaseHeaderStaging, false);

        PurchaseHeader.SetHideValidationDialog(true);
        if PurchaseHeaderStaging.remit_to <> '' then begin
            RemitVendorNo := GetVendorNo(PurchaseHeaderStaging, true);
            if RemitVendorNo <> PurchaseHeader."Pay-to Vendor No." then
                if RemitVendorNo <> '' then
                    PurchaseHeader.Validate("Pay-to Vendor No.", RemitVendorNo)
                else
                    PurchaseHeader.Validate("Pay-to Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        end else
            if PurchaseHeader."Pay-to Vendor No." <> PurchaseHeader."Buy-from Vendor No." then
                PurchaseHeader.Validate("Pay-to Vendor No.", PurchaseHeader."Buy-from Vendor No.");

        if PurchaseHeaderStaging.Closed <> 0DT then
            ClosedDate := DT2Date(PurchaseHeaderStaging.Closed)
        else
            ClosedDate := DT2Date(PurchaseHeaderStaging.Received);
        if ClosedDate <> 0D then begin
            PurchaseHeader.Validate("Posting Date", ClosedDate);
            PurchaseHeader.Validate("Document Date", ClosedDate);
        end;
        if PurchaseHeaderStaging.invoice_number <> '' then
            if PurchaseHeaderStaging.invoice_number <> PurchaseHeader."Vendor Invoice No." then
                SetVendorInvoiceNo(PurchaseHeader, PurchaseHeaderStaging.invoice_number);
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
                CopyPurchaseLineValues(PurchaseLine, PurchLineStaging);
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

    local procedure SetVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header"; InvoiceNo: Text)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorMgt: Codeunit "Vendor Mgt.";
        Parts: List of [Text];
    begin
        VendorMgt.SetFilterForExternalDocNo(VendorLedgerEntry, Enum::"Gen. Journal Document Type"::Invoice, InvoiceNo, PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Document Date");
        if not VendorLedgerEntry.IsEmpty() then
            if InvoiceNo.Contains('-') then begin
                Parts := InvoiceNo.Split('-');
                InvoiceNo := IncStr(Parts.Get(Parts.Count()));
            end else
                InvoiceNo := StrSubstNo('%1-2', InvoiceNo);
        PurchaseHeader.Validate("Vendor Invoice No.", CopyStr(InvoiceNo, 1, MaxStrLen(PurchaseHeader."Vendor Invoice No.")));
    end;

    procedure FixPurchaseOrderRounding(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeaderStaging: Record "EE Purch. Header Staging")
    var
        PurchaseLine: Record "Purchase Line";
        InitialCost, UpdateAmount : Decimal;
        LineNo: Integer;
    begin
        if PurchaseHeader."Amount Including VAT" > PurchaseHeaderStaging.grand_total then
            UpdateAmount := 0.01
        else
            UpdateAmount := -0.01;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("EE Part Id", GetOtherLineID());
        if PurchaseLine.FindFirst() then begin
            InitialCost := PurchaseLine."Unit Cost" - UpdateAmount;
            PurchaseLine.Validate("Unit Cost", InitialCost);
            PurchaseLine.Validate("Direct Unit Cost", InitialCost);
            PurchaseLine.Modify(true);
            exit;
        end;
        PurchaseLine.SetRange("EE Part Id", GetShippingLineID());
        if PurchaseLine.FindFirst() then begin
            InitialCost := PurchaseLine."Unit Cost" - UpdateAmount;
            PurchaseLine.Validate("Unit Cost", InitialCost);
            PurchaseLine.Validate("Direct Unit Cost", InitialCost);
            PurchaseLine.Modify(true);
            exit;
        end;
        PurchaseLine.SetRange("EE Part Id", GetTaxLineID());
        if PurchaseLine.FindFirst() then begin
            InitialCost := PurchaseLine."Unit Cost" - UpdateAmount;
            PurchaseLine.Validate("Unit Cost", InitialCost);
            PurchaseLine.Validate("Direct Unit Cost", InitialCost);
            PurchaseLine.Modify(true);
            exit;
        end;
        PurchaseLine.SetRange("EE Part Id");
        if PurchaseLine.FindLast() then
            LineNo := PurchaseLine."Line No.";
        AddExtraPurchLine(LineNo, PurchaseHeader."No.", 'Rounding Adjustment', UpdateAmount, GetOtherLineID());
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
        PurchaseLine.SetRange("EE Part Id");
    end;

    local procedure AddPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchLineStaging: Record "EE Purch. Line Staging"; DocNo: Code[20]; LineNo: Integer)
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", Enum::"Purchase Document Type"::Order);
        PurchaseLine.Validate("Document No.", DocNo);
        PurchaseLine.Validate("Line No.", LineNo);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", FleetRockSetup."Purchase Item No.");
        CopyPurchaseLineValues(PurchaseLine, PurchLineStaging);
        PurchaseLine.Validate("Tax Area Code", FleetrockSetup."Tax Area Code");
        PurchaseLine.Validate("Tax Group Code", FleetrockSetup."Non-Taxable Tax Group Code");
        PurchaseLine.Validate("EE Part Id", PurchLineStaging.part_id);
        PurchaseLine."EE Staging Line Entry No." := PurchLineStaging."Entry No."; //can't use validate as entry no will be zero for extra lines to handle taxes and other changes

        PurchaseLine.Insert(true);
    end;

    local procedure CopyPurchaseLineValues(var PurchaseLine: Record "Purchase Line"; var PurchLineStaging: Record "EE Purch. Line Staging")
    begin
        PurchaseLine.Validate("Qty. Rounding Precision", 0);
        PurchaseLine.Validate("Qty. Rounding Precision (Base)", 0);
        PurchaseLine.Validate(Quantity, PurchLineStaging.part_quantity);
        PurchaseLine.Validate("Unit Cost", PurchLineStaging.unit_price);
        PurchaseLine.Validate("Direct Unit Cost", PurchLineStaging.unit_price);
        PurchaseLine.Description := CopyStr(PurchLineStaging.part_description, 1, MaxStrLen(PurchaseLine.Description));
        PurchaseLine."Description 2" := CopyStr(PurchLineStaging.part_system_code, 1, MaxStrLen(PurchaseLine."Description 2"));
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
                RecRef.Field(FieldRec."No.").Value(CopyStr(JsonMgt.GetJsonValueAsText(OrderJsonObj, FieldRec.FieldName), 1, FieldRec.Len));
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
        Success := TryToHandleRepairUpdateResponse(T, OrderId, 'Failed to update Repair Order %1:\%2');
        InsertImportEntry(Success and (GetLastErrorText() = ''), 0, Enum::"EE Import Type"::"Repair Order",
            Enum::"EE Event Type"::Paid, Enum::"EE Direction"::Export, GetLastErrorText(), URL, 'POST', JsonBody);
        SalesInvHeader."EE Sent Payment" := Success;
        SalesInvHeader."EE Sent Payment DateTime" := CurrentDateTime();
        SalesInvHeader.Modify(true);
    end;

    [TryFunction]
    local procedure TryToHandleRepairUpdateResponse(var T: JsonToken; Id: Text; ErrorMsg: Text)
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
            Error(ErrorMsg, Id, JsonMgt.GetJsonValueAsText(ResponseObj, 'message'));
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






    [TryFunction]
    procedure TryToCreatePurchaseStagingFromRepairStaging(var SalesHeaderStaging: Record "EE Sales Header Staging"; var PurchHeaderStaging: Record "EE Purch. Header Staging")
    begin
        CreatePurchaseStagingFromRepairStaging(SalesHeaderStaging, PurchHeaderStaging);
    end;

    local procedure CreatePurchaseStagingFromRepairStaging(var SalesHeaderStaging: Record "EE Sales Header Staging"; var PurchHeaderStaging: Record "EE Purch. Header Staging")
    var
        PurchHeaderStaging2: Record "EE Purch. Header Staging";
        PurchLineStaging: Record "EE Purch. Line Staging";
        PartLineStaging: Record "EE Part Line Staging";
        TaskLineStaging: Record "EE Task Line Staging";
        EntryNo: Integer;
    begin
        PurchHeaderStaging2.LockTable(true);
        if PurchHeaderStaging2.FindLast() then
            EntryNo := PurchHeaderStaging2."Entry No.";
        EntryNo += 1;

        PurchHeaderStaging.Init();
        PurchHeaderStaging."Entry No." := EntryNo;
        PurchHeaderStaging.id := SalesHeaderStaging.id;
        PurchHeaderStaging.supplier_name := SalesHeaderStaging.vendor_name;
        PurchHeaderStaging.supplier_custom_id := SalesHeaderStaging.vendor_company_id;
        PurchHeaderStaging.invoice_number := SalesHeaderStaging.po_number;
        PurchHeaderStaging.tag := SalesHeaderStaging.tag;
        PurchHeaderStaging.tax_total := SalesHeaderStaging.tax_total;
        PurchHeaderStaging.other_total := SalesHeaderStaging.additional_charges;
        PurchHeaderStaging.subtotal := SalesHeaderStaging.part_total + SalesHeaderStaging.labor_total + SalesHeaderStaging.additional_charges;
        PurchHeaderStaging.grand_total := SalesHeaderStaging.grand_total;
        PurchHeaderStaging.date_created := SalesHeaderStaging.date_created;
        PurchHeaderStaging.date_closed := SalesHeaderStaging.date_invoiced;
        PurchHeaderStaging.date_opened := SalesHeaderStaging.date_started;
        PurchHeaderStaging.date_received := SalesHeaderStaging.date_invoiced;
        PurchHeaderStaging.remit_to := SalesHeaderStaging.remit_to;
        PurchHeaderStaging.remit_to_company_id := SalesHeaderStaging.remit_to_company_id;
        PurchHeaderStaging.Insert(true);

        SalesHeaderStaging."Purch. Staging Entry No." := PurchHeaderStaging."Entry No.";
        SalesHeaderStaging.Modify(true);

        PurchLineStaging.LockTable(true);
        if PurchLineStaging.FindLast() then
            EntryNo := PurchLineStaging."Entry No."
        else
            EntryNo := 0;


        TaskLineStaging.SetCurrentKey("Header Id", "Header Entry No.");
        TaskLineStaging.SetRange("Header Id", SalesHeaderStaging.id);
        TaskLineStaging.SetRange("Header Entry No.", SalesHeaderStaging."Entry No.");
        TaskLineStaging.SetAutoCalcFields("Part Lines");
        if TaskLineStaging.FindSet() then begin
            PartLineStaging.SetCurrentKey("Task Entry No.", "Task Id");
            repeat
                EntryNo += 1;
                PurchLineStaging.Init();
                PurchLineStaging."Entry No." := EntryNo;
                PurchLineStaging."Header Entry No." := PurchHeaderStaging."Entry No.";
                PurchLineStaging."Header Id" := PurchHeaderStaging.id;
                PurchLineStaging.part_id := TaskLineStaging.task_id;
                PurchLineStaging.part_number := TaskLineStaging.labor_type;
                PurchLineStaging.part_description := 'Labor';
                PurchLineStaging.part_quantity := TaskLineStaging.labor_hours;
                PurchLineStaging.unit_price := TaskLineStaging.labor_hourly_rate;
                PurchLineStaging.part_system_code := TaskLineStaging.labor_system_code;
                PurchLineStaging.line_total := TaskLineStaging.labor_hours * TaskLineStaging.labor_hourly_rate;
                PurchLineStaging.date_added := TaskLineStaging.date_added;
                PurchLineStaging.Insert(true);

                PartLineStaging.SetRange("Task Entry No.", TaskLineStaging."Entry No.");
                PartLineStaging.SetRange("Task Id", TaskLineStaging.task_id);
                if PartLineStaging.FindSet() then
                    repeat
                        EntryNo += 1;
                        PurchLineStaging.Init();
                        PurchLineStaging."Entry No." := EntryNo;
                        PurchLineStaging."Header Entry No." := PurchHeaderStaging."Entry No.";
                        PurchLineStaging."Header Id" := PurchHeaderStaging.id;
                        PurchLineStaging.part_id := PartLineStaging.task_part_id;
                        PurchLineStaging.part_number := PartLineStaging.part_number;
                        PurchLineStaging.part_description := PartLineStaging.part_description;
                        PurchLineStaging.part_quantity := PartLineStaging.part_quantity;
                        PurchLineStaging.unit_price := PartLineStaging.part_price;
                        PurchLineStaging.part_system_code := PartLineStaging.part_system_code;
                        PurchLineStaging.line_total := PartLineStaging.part_price * PartLineStaging.part_quantity;
                        PurchLineStaging.date_added := PartLineStaging.date_added;
                        PurchLineStaging.Insert(true);
                    until PartLineStaging.Next() = 0;
            until TaskLineStaging.Next() = 0;
        end;
    end;














    procedure CheckClaimSetup()
    begin
        FleetrockSetup.TestField("Claims Journal Template");
        FleetrockSetup.TestField("Claims Journal Batch");
        FleetrockSetup.TestField("Claims Labor G/L No.");
        FleetrockSetup.TestField("Claims Parts G/L No.");
    end;


    [TryFunction]
    procedure TryToGetClaims(StartDateTime: DateTime; Status: Enum "EE Event Type"; var ClaimsJsonArray: JsonArray; var URL: Text; UseVendorcAccount: Boolean)
    begin
        ClaimsJsonArray := GetClaims(StartDateTime, Status, URL, UseVendorcAccount);
    end;

    procedure GetClaims(StartDateTime: DateTime; Status: Enum "EE Event Type"; var URL: Text; UseVendorcAccount: Boolean): JsonArray
    var
        APIToken, UserName : Text;
        EndDateTime: DateTime;
    begin
        GetEventParameters(APIToken, StartDateTime, EndDateTime, UseVendorcAccount);
        CheckClaimSetup();
        if UseVendorcAccount then
            UserName := FleetrockSetup."Vendor Username"
        else
            UserName := FleetrockSetup.Username;
        URL := StrSubstNo('%1/API/GetClaims?username=%2&Status=%3&token=%4', FleetrockSetup."Integration URL", UserName, Status, APIToken);
        exit(RestAPIMgt.GetResponseAsJsonArray(URL, 'claims'));
    end;

    procedure GetAndImportClaim(ID: Text; UseVendorcAccount: Boolean)
    var
        GetRepairOrdersCU: Codeunit "EE Get Repair Orders";
        JsonArray, JsonArray2 : JsonArray;
        JTkn: JsonToken;
        JObjt: JsonObject;
        StartDateTime, EndDateTime : DateTime;
        APIToken, URL, Username : Text;
    begin
        StartDateTime := CurrentDateTime();
        GetEventParameters(APIToken, StartDateTime, EndDateTime, UseVendorcAccount);
        CheckClaimSetup();
        if UseVendorcAccount then
            UserName := FleetrockSetup."Vendor Username"
        else
            UserName := FleetrockSetup.Username;
        URL := StrSubstNo('%1/API/GetClaims?username=%2&ID=%3&token=%4', FleetrockSetup."Integration URL", UserName, ID, APIToken);
        JsonArray := RestAPIMgt.GetResponseAsJsonArray(URL, 'claims');

        foreach JTkn in JsonArray do begin
            JObjt := JTkn.AsObject();
            if JsonMgt.GetJsonValueAsText(JObjt, 'id') = ID then begin
                JsonArray2.Add(JObjt);
                //TODO
                // GetRepairOrdersCU.ImportRepairOrders(JsonArray2, Enum::"EE Repair Order Status"::Invoiced, Enum::"EE Event Type"::"Manual Import", URL);
                Error('NOT IMPLEMENTED: Importing claims is not yet implemented.');
                exit;
            end;
        end;

        Error('Claim with ID "%1" not found.', ID);
    end;







    [TryFunction]
    procedure TryToInsertClaimStagingRecords(var OrderJsonObj: JsonObject; var ImportEntryNo: Integer)
    begin
        ImportEntryNo := InsertClaimStagingRecords(OrderJsonObj);
    end;

    procedure InsertClaimStagingRecords(var OrderJsonObj: JsonObject): Integer
    var
        ClaimHeader: Record "EE Claim Header";
        EntryNo: Integer;
    begin
        if not TryToInsertClaimsStaging(OrderJsonObj, EntryNo) then begin
            if not ClaimHeader.Get(EntryNo) then begin
                ClaimHeader.Init();
                ClaimHeader."Entry No." := EntryNo;
                ClaimHeader.Insert(true);
            end;
            ClaimHeader."Import Error" := true;
            ClaimHeader."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(ClaimHeader."Error Message"));
            ClaimHeader.Modify(true);
            exit(EntryNo);
        end;
        ClaimHeader.Get(EntryNo);
        CreateClaimGenJournalLines(ClaimHeader);
        exit(EntryNo);
    end;

    [TryFunction]
    local procedure TryToInsertClaimsStaging(var OrderJsonObj: JsonObject; var EntryNo: Integer)
    var
        ClaimHeader: Record "EE Claim Header";
        ClaimLine: Record "EE Claim Line";
        UnitCosts: Dictionary of [Text, Decimal];
        TaskLines, PartLines : JsonArray;
        TaskLineJsonObj, PartLineJsonObj, PartObj : JsonObject;
        T: JsonToken;
        RecVar: Variant;
        APIToken, VendorAPIToken : Text;
        LineEntryNo: Integer;
    begin
        ClaimHeader.LockTable(true);
        if ClaimHeader.FindLast() then
            EntryNo := ClaimHeader."Entry No.";
        EntryNo += 1;
        ClaimHeader.Init();
        ClaimHeader."Entry No." := EntryNo;
        RecVar := ClaimHeader;
        PopulateStagingTable(RecVar, OrderJsonObj, Database::"EE Claim Header", ClaimHeader.FieldNo(id));
        ClaimHeader := RecVar;
        ClaimHeader.Insert(true);

        if not OrderJsonObj.Get('line_items', T) then
            exit;
        TaskLines := T.AsArray();
        if TaskLines.Count() = 0 then
            exit;
        ClaimLine.LockTable(true);
        if ClaimLine.FindLast() then
            LineEntryNo := ClaimLine."Entry No.";
        foreach T in TaskLines do begin
            LineEntryNo += 1;
            TaskLineJsonObj := T.AsObject();
            ClaimLine.Init();
            ClaimLine."Entry No." := LineEntryNo;
            ClaimLine."Header Entry No." := ClaimHeader."Entry No.";
            ClaimLine."Header Id" := ClaimHeader.id;
            RecVar := ClaimLine;
            PopulateStagingTable(RecVar, TaskLineJsonObj, Database::"EE Claim Line", ClaimLine.FieldNo("type"));
            ClaimLine := RecVar;
            ClaimLine.Insert(true);
        end;
    end;


    procedure CreateClaimGenJournalLines(var ClaimHeader: Record "EE Claim Header")
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        ClaimLine: Record "EE Claim Line";
        LineNo: Integer;
    begin
        ClaimLine.SetRange("Header Entry No.", ClaimHeader."Entry No.");
        if not ClaimLine.FindSet() then
            exit;

        GenJournalLine.SetRange("Journal Template Name", FleetrockSetup."Claims Journal Template");
        GenJournalLine.SetRange("Journal Batch Name", FleetrockSetup."Claims Journal Batch");
        if GenJournalLine.FindLast() then
            LineNo := GenJournalLine."Line No.";
        repeat
            LineNo += 10000;
            GenJournalLine.Init();
            GenJournalLine.Validate("Journal Template Name", FleetrockSetup."Claims Journal Template");
            GenJournalLine.Validate("Journal Batch Name", FleetrockSetup."Claims Journal Batch");
            GenJournalLine.Validate("Line No.", LineNo);
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
            GenJournalLine.Validate("Document No.", ClaimHeader.id);
            GenJournalLine.Validate("Amount (LCY)", ClaimLine.quantity * ClaimLine.unit_price);
            GenJournalLine.Validate("Job Unit Cost (LCY)", ClaimLine.unit_price);
            GenJournalLine.Validate("Posting Date", DT2Date(ClaimHeader."Closed DateTime"));
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
            if ClaimLine.type = 'labor' then
                GenJournalLine.Validate("Account No.", FleetrockSetup."Claims Labor G/L No.")
            else
                GenJournalLine.Validate("Account No.", FleetrockSetup."Claims Parts G/L No.");
            GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
            GenJournalLine.Validate("Bal. Account No.", GetVendorNoAndUpdate(ClaimHeader.supplier_name));
            GenJournalLine.Validate("External Document No.", CopyStr(ClaimHeader.credit_number, 1, MaxStrLen(GenJournalLine."External Document No.")));
            GenJournalLine.Description := CopyStr(ClaimLine.description, 1, MaxStrLen(GenJournalLine.Description));
            GenJournalLine.Insert(true);
        until ClaimLine.Next() = 0;
    end;
































    procedure InsertImportEntry(Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type";
                                                                                    Direction: Enum "EE Direction";
                                                                                    ErrorMsg: Text;
                                                                                    URL: Text;
                                                                                    Method: Text)
    var
        JsonBody: JsonObject;
        EntryNo: Integer;
    begin
        InsertImportEntry(EntryNo, Success, ImportEntryNo, Type, EventType, Direction, ErrorMsg, URL, Method, JsonBody, '');
    end;

    procedure InsertImportEntry(Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type";
                                                                                    Direction: Enum "EE Direction";
                                                                                    ErrorMsg: Text;
                                                                                    URL: Text;
                                                                                    Method: Text; var JsonBody: JsonObject)
    var
        EntryNo: Integer;
    begin
        InsertImportEntry(EntryNo, Success, ImportEntryNo, Type, EventType, Direction, ErrorMsg, URL, Method, JsonBody, '');
    end;

    procedure InsertImportEntry(Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type";
                                                                                    Direction: Enum "EE Direction";
                                                                                    ErrorMsg: Text;
                                                                                    URL: Text;
                                                                                    Method: Text; var JsonBody: JsonObject; DocNo: Code[20])
    var
        EntryNo: Integer;
    begin
        InsertImportEntry(EntryNo, Success, ImportEntryNo, Type, EventType, Direction, ErrorMsg, URL, Method, JsonBody, DocNo);
    end;


    // procedure InsertImportEntry(var EntryNo: Integer; Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type"; Direction: Enum "EE Direction"; ErrorMsg: Text; URL: Text; Method: Text)
    // var
    //     JsonBody: JsonObject;
    // begin
    //     InsertImportEntry(EntryNo, Success, ImportEntryNo, Type, EventType, Direction, ErrorMsg, URL, Method, JsonBody);
    // end;

    procedure InsertImportEntry(var EntryNo: Integer; Success: Boolean; ImportEntryNo: Integer; Type: Enum "EE Import Type"; EventType: Enum "EE Event Type";
                                                                                                          Direction: Enum "EE Direction";
                                                                                                          ErrorMsg: Text;
                                                                                                          URL: Text;
                                                                                                          Method: Text; var JsonBody: JsonObject; DocNo: Code[20])
    var
        ImportEntry: Record "EE Import/Export Entry";
        PurchHeaderStaging: Record "EE Purch. Header Staging";
        SalesHeaderStaging: Record "EE Sales Header Staging";
        s: Text;
    begin
        if DocNo = '' then
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
        ImportEntry.LockTable(true);
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
        SingleInstance: Codeunit "EE Single Instance";
        LoadedSetup, LoadedVendorSetup : Boolean;
}