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
        JsonArry, VendorJsonArray : JsonArray;
        URL: Text;
    begin
        if Rec."Parameter String" = 'invoiced' then begin
            OrderStatus := OrderStatus::invoiced;
            EventType := EventType::invoiced;
        end else begin
            OrderStatus := OrderStatus::started;
            EventType := EventType::Started;
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
                EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');


        FleetRockSetup.Get();
        if FleetRockSetup."Import Repair with Vendor" and (FleetRockSetup."Vendor API Key" <> '') then
            if not FleetRockMgt.TryToGetRepairOrders(StartDateTime, OrderStatus, VendorJsonArray, URL, true) then
                FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::"Repair Order",
                    EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET')
            else
                if (VendorJsonArray.Count() > 0) and (VendorJsonArray.Count() <> JsonArry.Count()) then
                    MergeJsonArrays(VendorJsonArray, JsonArry);

        if JsonArry.Count() <> 0 then
            ImportRepairOrders(JsonArry, OrderStatus, EventType, URL);
    end;

    procedure SetStartDateTime(NewStartDateTime: DateTime)
    begin
        StartDateTime := NewStartDateTime;
        HasSetStartDateTime := true;
    end;


    procedure ImportRepairOrders(var JsonArry: JsonArray; OrderStatus: Enum "EE Repair Order Status"; EventType: Enum "EE Event Type"; URL: Text): Boolean
    var
        FleetRockSetup: Record "EE Fleetrock Setup";
        OrderJsonObj: JsonObject;
        T: JsonToken;
        Tags: Text;
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
            Tags := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'tag');
            if GetPurchaseOrders.CheckTagForImport(FleetRockSetup."Import Tags", Tags) then begin
                ImportEntryNo := 0;
                Success := false;
                LogEntry := false;
                ClearLastError();
                if FleetRockSetup."Import Repairs as Purchases" then
                    Success := ImportAsPurchaseOrder(FleetRockSetup, OrderJsonObj, OrderStatus, ImportEntryNo, LogEntry)
                else
                    Success := ImportAsSalesInvoice(FleetRockSetup, OrderJsonObj, OrderStatus, ImportEntryNo, LogEntry);
                if LogEntry then
                    FleetRockMgt.InsertImportEntry(Success and (GetLastErrorText() = ''), ImportEntryNo, ImportType, EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');
            end;
        end;
    end;

    local procedure ImportAsPurchaseOrder(var FleetrockSetup: Record "EE Fleetrock Setup"; var OrderJsonObj: JsonObject; OrderStatus: Enum "EE Repair Order Status"; var ImportEntryNo: Integer; var LogEntry: Boolean): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderStaging: Record "EE Purch. Header Staging";
        SalesHeaderStaging: Record "EE Sales Header Staging";
        OrderId: Text;
        Success: Boolean;
    begin
        if OrderStatus = OrderStatus::invoiced then begin
            LogEntry := true;
            if not TryToGetOrderID(OrderJsonObj, OrderId, Enum::"EE Import Type"::"Purchase Order") then
                exit(false);
            PurchInvHeader.SetCurrentKey("EE Fleetrock ID");
            PurchInvHeader.SetRange("EE Fleetrock ID", CopyStr(OrderId, 1, MaxStrLen(PurchInvHeader."EE Fleetrock ID")));
            if not PurchInvHeader.IsEmpty() then begin
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
            if FleetRockMgt.TryToInsertROStagingRecords(OrderJsonObj, ImportEntryNo, false) and SalesHeaderStaging.Get(ImportEntryNo) then
                if FleetRockMgt.TryToCreatePurchaseStagingFromRepairStaging(SalesHeaderStaging, PurchaseHeaderStaging) then
                    Success := GetPurchaseOrders.UpdateAndPostPurchaseOrder(FleetrockSetup, PurchaseHeaderStaging);
            if PurchaseHeaderStaging."Document No." <> '' then begin
                SalesHeaderStaging."Purch. Document No." := PurchaseHeaderStaging."Document No.";
                SalesHeaderStaging.Modify(true);
            end;
        end;
        exit(Success);
    end;

    local procedure ImportAsSalesInvoice(var FleetrockSetup: Record "EE Fleetrock Setup"; var OrderJsonObj: JsonObject; OrderStatus: Enum "EE Repair Order Status"; var ImportEntryNo: Integer; var LogEntry: Boolean): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeaderStaging: Record "EE Sales Header Staging";
        OrderId: Text;
        Success: Boolean;
    begin
        if OrderStatus = OrderStatus::invoiced then begin
            LogEntry := true;
            if HasSetStartDateTime then begin
                if not TryToGetOrderID(OrderJsonObj, OrderId, Enum::"EE Import Type"::"Repair Order") then
                    exit(false);
                SalesInvHeader.SetCurrentKey("EE Fleetrock ID");
                SalesInvHeader.SetRange("EE Fleetrock ID", CopyStr(OrderId, 1, MaxStrLen(SalesInvHeader."EE Fleetrock ID")));
                if not SalesInvHeader.IsEmpty() then begin
                    LogEntry := false;
                    exit(true);
                end;
            end;
            if FleetRockMgt.TryToInsertROStagingRecords(OrderJsonObj, ImportEntryNo, false) and SalesHeaderStaging.Get(ImportEntryNo) then begin
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
        end else
            if JsonMgt.GetJsonValueAsText(OrderJsonObj, 'status') = 'In Progress' then begin
                LogEntry := true;
                if FleetRockMgt.TryToCheckIfAlreadyImported(JsonMgt.GetJsonValueAsText(OrderJsonObj, 'id'), SalesHeader) then
                    Success := FleetRockMgt.TryToInsertROStagingRecords(OrderJsonObj, ImportEntryNo, true);
            end;
        exit(Success);
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




    local procedure MergeJsonArrays(var VendorJsonArray: JsonArray; var CustomerVendorArray: JsonArray)
    var
        JsonBuffer: Record "JSON Buffer" temporary;
        JTkn: JsonToken;
        JObj: JsonObject;
        VendorROs, CustomerROs, DeltaROs : List of [Text];
        s: Text;
    begin
        VendorJsonArray.WriteTo(s);
        JsonBuffer.ReadFromText(s);
        JsonBuffer.SetRange(Depth, 1);
        if JsonBuffer.FindSet() then
            repeat
                if JsonBuffer.GetPropertyValue(s, 'id') then
                    if not VendorROs.Contains(s) then
                        VendorROs.Add(s);
            until JsonBuffer.Next() = 0;

        CustomerVendorArray.WriteTo(s);
        JsonBuffer.Reset();
        JsonBuffer.ReadFromText(s);
        JsonBuffer.SetRange(Depth, 1);
        if JsonBuffer.FindSet() then
            repeat
                if JsonBuffer.GetPropertyValue(s, 'id') then
                    if not CustomerROs.Contains(s) then
                        CustomerROs.Add(s);
            until JsonBuffer.Next() = 0;

        foreach s in VendorROs do
            if not CustomerROs.Contains(s) then
                DeltaROs.Add(s);

        if DeltaROs.Count() = 0 then
            exit;

        foreach JTkn in VendorJsonArray do begin
            JObj := JTkn.AsObject();
            if DeltaROs.Contains(JsonMgt.GetJsonValueAsText(JObj, 'id')) then
                CustomerVendorArray.Add(JTkn);
        end;
    end;

    var
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        GetPurchaseOrders: Codeunit "EE Get Purchase Orders";
        JsonMgt: Codeunit "EE Json Mgt.";
        StartDateTime: DateTime;
        HasSetStartDateTime: Boolean;
}