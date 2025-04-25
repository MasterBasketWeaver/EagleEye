codeunit 80001 "EE Get Purchase Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Import/Export Entry" = r;


    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderStaging: Record "EE Purch. Header Staging";
        ImportEntry: Record "EE Import/Export Entry";
        FleetrockSetup: Record "EE Fleetrock Setup";
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        JsonMgt: Codeunit "EE Json Mgt.";
        OrderStatus: Enum "EE Repair Order Status";
        EventType: Enum "EE Event Type";
        JsonArry: JsonArray;
        T: JsonToken;
        OrderJsonObj: JsonObject;
        JsonVal: JsonValue;
        StartDateTime: DateTime;
        URL, s : Text;
        DocNo: Code[20];
        ImportEntryNo: Integer;
        Success, IsReceived, LogEntry : Boolean;
    begin
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
            FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::"Purchase Order",
                EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');
            exit;
        end;
        if JsonArry.Count() = 0 then
            exit;
        FleetRockSetup.Get();
        PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
        LogEntry := not IsReceived;
        foreach T in JsonArry do begin
            OrderJsonObj := T.AsObject();
            OrderJsonObj.Get('id', T);
            JsonVal := T.AsValue();
            s := JsonVal.AsText();
            ImportEntryNo := 0;
            ClearLastError();
            Success := false;
            if IsReceived then begin
                if JsonMgt.GetJsonValueAsText(OrderJsonObj, 'status') = 'Received' then begin
                    LogEntry := true;
                    if FleetRockMgt.TryToCheckIfAlreadyImported(s, PurchaseHeader) then
                        Success := FleetRockMgt.TryToInsertPOStagingRecords(OrderJsonObj, ImportEntryNo, true);
                end;
            end else begin
                LogEntry := true;
                if FleetRockMgt.TryToInsertPOStagingRecords(OrderJsonObj, ImportEntryNo, false) and PurchaseHeaderStaging.Get(ImportEntryNo) then begin
                    PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
                    PurchaseHeader.SetRange("EE Fleetrock ID", PurchaseHeaderStaging.id);
                    if PurchaseHeader.FindFirst() then
                        Success := FleetRockMgt.TryToUpdatePurchaseOrder(PurchaseHeaderStaging, PurchaseHeader)
                    else
                        if FleetRockMgt.TryToCreatePurchaseOrder(PurchaseHeaderStaging, DocNo) then
                            Success := FleetRockMgt.TryToUpdatePurchaseOrder(PurchaseHeaderStaging, DocNo);
                    if Success then
                        if FleetRockSetup."Auto-post Purchase Orders" then begin
                            PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeaderStaging."Document No.");
                            PurchaseHeader.Receive := true;
                            PurchaseHeader.Invoice := true;
                            Success := TryToPostOrder(PurchaseHeader);
                        end;
                end;
            end;
            if LogEntry then
                FleetRockMgt.InsertImportEntry(Success and (GetLastErrorText() = ''), ImportEntryNo,
                    ImportEntry."Document Type"::"Purchase Order", EventType, Enum::"EE Direction"::Import,
                    GetLastErrorText(), URL, 'GET');
        end;
    end;

    [TryFunction]
    local procedure TryToPostOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);
    end;
}