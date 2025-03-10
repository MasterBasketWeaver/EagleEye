codeunit 80001 "EE Get Purchase Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Import/Export Entry" = r;


    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderStaging: Record "EE Purch. Header Staging";
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        ImportEntry: Record "EE Import/Export Entry";
        OrderStatus: Enum "EE Repair Order Status";
        EventType: Enum "EE Event Type";
        JsonArry: JsonArray;
        T: JsonToken;
        OrderJsonObj: JsonObject;
        JsonVal: JsonValue;
        StartDateTime: DateTime;
        URL, s : Text;
        EntryNo, ImportEntryNo : Integer;
        Success, IsReceived : Boolean;
    begin
        if ImportEntry.FindLast() then
            EntryNo := ImportEntry."Entry No.";

        if Rec."Parameter String" = 'received' then begin
            IsReceived := true;
            EventType := EventType::Received
        end else
            EventType := EventType::Closed;

        ImportEntry.SetRange("Document Type", ImportEntry."Document Type"::"Purchase Order");
        ImportEntry.SetRange(Success, true);
        ImportEntry.SetRange("Event Type", EventType);
        if ImportEntry.FindLast() then
            StartDateTime := ImportEntry.SystemCreatedAt;

        if not FleetRockMgt.TryToGetPurchaseOrders(StartDateTime, JsonArry, URL, EventType) then begin
            FleetRockMgt.InsertImportEntry(EntryNo + 1, false, 0, ImportEntry."Document Type"::"Purchase Order",
                EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');
            exit;
        end;
        if JsonArry.Count() = 0 then
            exit;

        PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
        foreach T in JsonArry do begin
            OrderJsonObj := T.AsObject();
            OrderJsonObj.Get('id', T);
            JsonVal := T.AsValue();
            s := JsonVal.AsText();
            ImportEntryNo := 0;
            ClearLastError();
            Success := false;
            if IsReceived then begin
                if FleetRockMgt.GetJsonValueAsText(OrderJsonObj, 'status') = 'Received' then
                    if FleetRockMgt.TryToCheckIfAlreadyImported(s, PurchaseHeader) then
                        Success := FleetRockMgt.TryToInsertPOStagingRecords(OrderJsonObj, ImportEntryNo, true);
            end else begin
                if FleetRockMgt.TryToInsertPOStagingRecords(OrderJsonObj, ImportEntryNo, false) and PurchaseHeaderStaging.Get(ImportEntryNo) then begin
                    PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
                    PurchaseHeader.SetRange("EE Fleetrock ID", PurchaseHeaderStaging.id);
                    if not PurchaseHeader.FindFirst() then begin
                        FleetRockMgt.CreatePurchaseOrder(PurchaseHeaderStaging);
                        if PurchaseHeaderStaging."Document No." <> '' then
                            Success := FleetRockMgt.TryToUpdatePurchaseOrder(PurchaseHeaderStaging, PurchaseHeaderStaging."Document No.");
                    end else
                        Success := FleetRockMgt.TryToUpdatePurchaseOrder(PurchaseHeaderStaging, PurchaseHeader."No.");
                end;
            end;
            EntryNo += 1;
            FleetRockMgt.InsertImportEntry(EntryNo, Success and (GetLastErrorText() = ''), ImportEntryNo,
                ImportEntry."Document Type"::"Purchase Order", EventType, Enum::"EE Direction"::Import,
                GetLastErrorText(), URL, 'GET');
        end;
    end;
}