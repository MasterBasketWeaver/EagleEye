codeunit 80003 "EE Get Repair Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Import/Export Entry" = r;

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        FleetRockSetup: Record "EE Fleetrock Setup";
        ImportEntry: Record "EE Import/Export Entry";
        SalesHeaderStaging: Record "EE Sales Header Staging";
        OrderStatus: Enum "EE Repair Order Status";
        EventType: Enum "EE Event Type";
        JsonArry, VendorJsonArray, ExtraArray : JsonArray;
        URL: Text;
        FourHourDuration: Duration;
    begin
        if Rec."Parameter String" = 'invoiced' then begin
            OrderStatus := OrderStatus::invoiced;
            EventType := EventType::Invoiced;
        end else begin
            OrderStatus := OrderStatus::finished;
            EventType := EventType::Finished;
            HasSetStartDateTime := true;
            FourHourDuration := 1000 * 60 * 60 * 4;
            StartDateTime := CurrentDateTime() - FourHourDuration;
        end;

        if not HasSetStartDateTime then begin
            ImportEntry.SetRange("Document Type", ImportEntry."Document Type"::"Repair Order");
            ImportEntry.SetRange("Event Type", EventType);
            ImportEntry.SetRange(Success, true);
            if ImportEntry.FindLast() then
                StartDateTime := ImportEntry.SystemCreatedAt;
        end;

        if not FleetRockMgt.TryToGetRepairOrders(StartDateTime, OrderStatus, JsonArry, URL, false) then
            FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::"Repair Order",
                EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET', FleetRockSetup.Username);


        FleetRockSetup.Get();
        if FleetRockSetup."Import Repair with Vendor" and (FleetRockSetup."Vendor API Key" <> '') then
            if not FleetRockMgt.TryToGetRepairOrders(StartDateTime, OrderStatus, VendorJsonArray, URL, true) then
                FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::"Repair Order",
                    EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET', FleetRockSetup."Vendor Username")
            else
                if (VendorJsonArray.Count() > 0) and (JsonArry.Count() > 0) then
                    ExtraArray := GetDeltaOfArrays(VendorJsonArray, JsonArry);


        if JsonArry.Count() > 0 then
            ImportRepairOrders(JsonArry, OrderStatus, EventType, URL, FleetRockSetup.Username);
        if ExtraArray.Count() > 0 then
            ImportRepairOrders(ExtraArray, OrderStatus, EventType, URL, FleetRockSetup."Vendor Username");

        if EventType = EventType::Invoiced then
            exit;

        EventType := EventType::Started;
        OrderStatus := OrderStatus::started;
        Clear(JsonArry);
        Clear(VendorJsonArray);
        Clear(ExtraArray);
        if not FleetRockMgt.TryToGetRepairOrders(StartDateTime, OrderStatus, JsonArry, URL, false) then
            FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::"Repair Order",
                EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET', FleetRockSetup.Username);

        if FleetRockSetup."Import Repair with Vendor" and (FleetRockSetup."Vendor API Key" <> '') then
            if not FleetRockMgt.TryToGetRepairOrders(StartDateTime, OrderStatus, VendorJsonArray, URL, true) then
                FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::"Repair Order",
                    EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET', FleetRockSetup."Vendor Username")
            else
                if (VendorJsonArray.Count() > 0) and (VendorJsonArray.Count() <> JsonArry.Count()) then
                    ExtraArray := GetDeltaOfArrays(VendorJsonArray, JsonArry);

        if JsonArry.Count() > 0 then
            ImportRepairOrders(JsonArry, OrderStatus, EventType, URL, FleetRockSetup.Username);
        if ExtraArray.Count() > 0 then
            ImportRepairOrders(ExtraArray, OrderStatus, EventType, URL, FleetRockSetup."Vendor Username");
    end;

    procedure SetStartDateTime(NewStartDateTime: DateTime)
    begin
        StartDateTime := NewStartDateTime;
        HasSetStartDateTime := true;
    end;



    procedure ImportRepairOrders(var JsonArry: JsonArray; OrderStatus: Enum "EE Repair Order Status"; EventType: Enum "EE Event Type"; URL: Text; Username: Text): Boolean
    var
        FleetRockSetup: Record "EE Fleetrock Setup";
        OrderJsonObj: JsonObject;
        T: JsonToken;
        ImportType: Enum "EE Import Type";
        ImportEntryNo: Integer;
        Success, LogEntry : Boolean;
    begin
        FleetRockSetup.Get();
        if FleetRockSetup."Import Repairs as Purchases" then begin
            FleetRockMgt.CheckPurchaseOrderSetup(FleetRockSetup);
            ImportType := ImportType::"Purchase Order";
        end else
            ImportType := ImportType::"Repair Order";
        foreach T in JsonArry do begin
            OrderJsonObj := T.AsObject();
            if IsValidToImport(FleetRockSetup, OrderJsonObj) then begin
                ImportEntryNo := 0;
                Success := false;
                LogEntry := false;
                ClearLastError();
                if FleetRockSetup."Import Repairs as Purchases" then
                    Success := ImportAsPurchaseOrder(FleetRockSetup, OrderJsonObj, OrderStatus, ImportEntryNo, LogEntry, Username)
                else
                    Success := ImportAsSalesInvoice(FleetRockSetup, OrderJsonObj, OrderStatus, ImportEntryNo, LogEntry, Username);
                if LogEntry then
                    FleetRockMgt.InsertImportEntry(Success and (GetLastErrorText() = ''), ImportEntryNo, ImportType, EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET', Username);
            end;
        end;
    end;


    procedure IsValidToImport(var OrderJsonObj: JsonObject): Boolean
    var
        FleetrockSetup: Record "EE Fleetrock Setup";
    begin
        FleetrockSetup.Get();
        exit(IsValidToImport(FleetrockSetup, OrderJsonObj));
    end;

    procedure IsValidToImport(var FleetrockSetup: Record "EE Fleetrock Setup"; var OrderJsonObj: JsonObject): Boolean
    begin
        if FleetRockSetup."Import Repairs as Purchases" then
            exit(FleetRockMgt.IsValidCustomer(JsonMgt.GetJsonValueAsText(OrderJsonObj, 'customer_name')));
        if FleetRockMgt.IsValidVendor(JsonMgt.GetJsonValueAsText(OrderJsonObj, 'vendor_company_id')) then
            exit(true);
        exit(FleetRockMgt.IsValidVendor(JsonMgt.GetJsonValueAsText(OrderJsonObj, 'vendor_name')));
    end;


    local procedure ImportAsPurchaseOrder(var FleetrockSetup: Record "EE Fleetrock Setup"; var OrderJsonObj: JsonObject; OrderStatus: Enum "EE Repair Order Status"; var ImportEntryNo: Integer; var LogEntry: Boolean; Username: Text): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderStaging: Record "EE Purch. Header Staging";
        SalesHeaderStaging: Record "EE Sales Header Staging";
        OrderId: Text;
        Success: Boolean;
    begin
        LogEntry := true;
        if not TryToGetOrderID(OrderJsonObj, OrderId, Enum::"EE Import Type"::"Purchase Order") then
            exit(false);
        if FleetRockMgt.CheckIfPurchaseInvAlreadyImported(OrderId, false) then begin
            LogEntry := false;
            exit(true);
        end;
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("EE Fleetrock ID", CopyStr(OrderId, 1, MaxStrLen(PurchaseHeader."EE Fleetrock ID")));
        if PurchaseHeader.FindFirst() then begin
            PurchaseHeaderStaging.SetRange(id, PurchaseHeader."EE Fleetrock ID");
            PurchaseHeaderStaging.SetRange("Document No.", PurchaseHeader."No.");
            if PurchaseHeaderStaging.FindLast() then begin
                PurchaseHeader.CalcFields("Amount Including VAT");
                if Abs(Round(PurchaseHeader."Amount Including VAT", 0.01) - Round(PurchaseHeaderStaging.grand_total, 0.01)) <= 0.01 then begin
                    LogEntry := false;
                    exit(true);
                end;
            end;
            PurchaseHeaderStaging.Reset();
        end;
        PurchaseHeader.Reset();
        if FleetRockMgt.TryToInsertROStagingRecords(OrderJsonObj, ImportEntryNo, false, Username) and SalesHeaderStaging.Get(ImportEntryNo) then
            if FleetRockMgt.TryToCreatePurchaseStagingFromRepairStaging(SalesHeaderStaging, PurchaseHeaderStaging) then begin
                if OrderStatus = OrderStatus::invoiced then
                    Success := GetPurchaseOrders.UpdateAndPostPurchaseOrder(FleetrockSetup, PurchaseHeaderStaging)
                else
                    Success := FleetRockMgt.CreatePurchaseOrder(PurchaseHeaderStaging);
                ImportEntryNo := PurchaseHeaderStaging."Entry No.";
            end;
        if PurchaseHeaderStaging."Document No." <> '' then begin
            SalesHeaderStaging."Purch. Document No." := PurchaseHeaderStaging."Document No.";
            SalesHeaderStaging.Modify(true);
        end;
        exit(Success);
    end;

    local procedure ImportAsSalesInvoice(var FleetrockSetup: Record "EE Fleetrock Setup"; var OrderJsonObj: JsonObject; OrderStatus: Enum "EE Repair Order Status"; var ImportEntryNo: Integer; var LogEntry: Boolean; Username: Text): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderStaging: Record "EE Sales Header Staging";
        OrderId, Status : Text;
        Success: Boolean;
    begin
        if OrderStatus = OrderStatus::invoiced then begin
            LogEntry := true;
            if HasSetStartDateTime then begin
                if not TryToGetOrderID(OrderJsonObj, OrderId, Enum::"EE Import Type"::"Repair Order") then
                    exit(false);
                if FleetRockMgt.CheckIfSalesInvAlreadyImported(OrderId, false) then begin
                    LogEntry := false;
                    exit(true);
                end;
            end;
            if FleetRockMgt.TryToInsertROStagingRecords(OrderJsonObj, ImportEntryNo, false, Username) and SalesHeaderStaging.Get(ImportEntryNo) then begin
                SalesHeader.SetCurrentKey("EE Fleetrock ID");
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                SalesHeader.SetRange("EE Fleetrock ID", SalesHeaderStaging.id);
                if not SalesHeader.FindFirst() then begin
                    FleetRockMgt.CreateSalesOrder(SalesHeaderStaging);
                    if SalesHeaderStaging."Document No." <> '' then
                        Success := FleetRockMgt.TryToUpdateRepairOrder(SalesHeaderStaging, SalesHeaderStaging."Document No.");
                end else
                    Success := FleetRockMgt.TryToUpdateRepairOrder(SalesHeaderStaging, SalesHeader."No.");
                if Success then
                    if FleetRockSetup."Auto-post Repair Orders" then begin
                        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesHeaderStaging."Document No.");
                        Commit();
                        Success := Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
                    end;
            end;
            exit(Success);
        end;
        Status := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'status').ToUpper();
        if ((OrderStatus = OrderStatus::started) and (Status.ToUpper() = InProgressStatus)) or ((OrderStatus = OrderStatus::finished) and (Status = FinishedStatus)) then begin
            if not FleetRockMgt.TryToCheckIfAlreadyImported(JsonMgt.GetJsonValueAsText(OrderJsonObj, 'id'), SalesHeader) then
                exit(false);
            LogEntry := true;
            exit(FleetRockMgt.TryToInsertROStagingRecords(OrderJsonObj, ImportEntryNo, true, Username));
        end;
    end;

    [TryFunction]
    local procedure TryToGetOrderID(var OrderJsonObj: JsonObject; var OrderId: Text; ImportType: Enum "EE Import Type")
    begin
        OrderId := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'id');
        if OrderId = '' then begin
            OrderJsonObj.WriteTo(OrderId);
            Error('%1 ID is missing in the JSON object.\%2', ImportType, OrderId);
        end;
    end;




    local procedure MergeJsonArrays(var VendorJsonArray: JsonArray; var CustomerJsonArray: JsonArray)
    var
        JTkn: JsonToken;
        JObj: JsonObject;
        DeltaROs: List of [Text];
    begin
        DeltaROs := GetArrayDeltaAsList(VendorJsonArray, CustomerJsonArray);
        if DeltaROs.Count() <> 0 then
            foreach JTkn in VendorJsonArray do begin
                JObj := JTkn.AsObject();
                if DeltaROs.Contains(JsonMgt.GetJsonValueAsText(JObj, 'id')) then
                    CustomerJsonArray.Add(JTkn);
            end;
    end;

    local procedure GetDeltaOfArrays(var VendorJsonArray: JsonArray; var CustomerJsonArray: JsonArray): JsonArray
    var
        DeltaArray: JsonArray;
        JTkn: JsonToken;
        JObj: JsonObject;
        DeltaROs: List of [Text];
    begin
        DeltaROs := GetArrayDeltaAsList(VendorJsonArray, CustomerJsonArray);
        if DeltaROs.Count() <> 0 then
            foreach JTkn in VendorJsonArray do begin
                JObj := JTkn.AsObject();
                if DeltaROs.Contains(JsonMgt.GetJsonValueAsText(JObj, 'id')) then
                    DeltaArray.Add(JTkn);
            end;
        exit(DeltaArray);
    end;

    local procedure GetArrayDeltaAsList(var Array1: JsonArray; var Array2: JsonArray): List of [Text]
    var
        JsonBuffer: Record "JSON Buffer" temporary;
        JTkn: JsonToken;
        JObj: JsonObject;
        List1, List2, DeltaList : List of [Text];
        s: Text;
    begin
        Array1.WriteTo(s);
        JsonBuffer.ReadFromText(s);
        JsonBuffer.SetRange(Depth, 1);
        if JsonBuffer.FindSet() then
            repeat
                if JsonBuffer.GetPropertyValue(s, 'id') then
                    if not List1.Contains(s) then
                        List1.Add(s);
            until JsonBuffer.Next() = 0;

        Array2.WriteTo(s);
        JsonBuffer.Reset();
        JsonBuffer.ReadFromText(s);
        JsonBuffer.SetRange(Depth, 1);
        if JsonBuffer.FindSet() then
            repeat
                if JsonBuffer.GetPropertyValue(s, 'id') then
                    if not List2.Contains(s) then
                        List2.Add(s);
            until JsonBuffer.Next() = 0;

        foreach s in List1 do
            if not List2.Contains(s) then
                DeltaList.Add(s);

        exit(DeltaList);
    end;

    var
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        GetPurchaseOrders: Codeunit "EE Get Purchase Orders";
        JsonMgt: Codeunit "EE Json Mgt.";
        Usernames: Dictionary of [Text, Text];
        StartDateTime: DateTime;
        HasSetStartDateTime: Boolean;
        InProgressStatus: Label 'IN PROGRESS';
        FinishedStatus: Label 'FINISHED';
}