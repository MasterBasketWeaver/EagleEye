codeunit 80003 "EE Get Repair Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Import/Export Entry" = r;

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        ImportEntry: Record "EE Import/Export Entry";
        SalesHeaderStaging: Record "EE Sales Header Staging";
        FleetRockSetup: Record "EE Fleetrock Setup";
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        JsonMgt: Codeunit "EE Json Mgt.";
        OrderStatus: Enum "EE Repair Order Status";
        EventType: Enum "EE Event Type";
        JsonArry: JsonArray;
        OrderJsonObj: JsonObject;
        T: JsonToken;
        StartDateTime: DateTime;
        URL, Tags : Text;
        ImportEntryNo: Integer;
        Success, LogEntry : Boolean;
    begin
        if Rec."Parameter String" = 'invoiced' then begin
            OrderStatus := OrderStatus::invoiced;
            EventType := EventType::invoiced;
        end else begin
            OrderStatus := OrderStatus::started;
            EventType := EventType::Started;
        end;

        ImportEntry.SetRange("Document Type", ImportEntry."Document Type"::"Repair Order");
        ImportEntry.SetRange("Event Type", EventType);
        ImportEntry.SetRange(Success, true);
        if ImportEntry.FindLast() then
            StartDateTime := ImportEntry.SystemCreatedAt;

        if not FleetRockMgt.TryToGetRepairOrders(StartDateTime, OrderStatus, JsonArry, URL) then begin
            FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::"Repair Order",
                EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');
            exit;
        end;
        if JsonArry.Count() = 0 then
            exit;
        FleetRockSetup.Get();
        SalesHeader.SetCurrentKey("EE Fleetrock ID");
        foreach T in JsonArry do begin
            OrderJsonObj := T.AsObject();
            Tags := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'tag');
            if (FleetRockSetup."Import Tag" = '') or Tags.Contains(FleetRockSetup."Import Tag") then begin
                ImportEntryNo := 0;
                Success := false;
                LogEntry := false;
                ClearLastError();
                if OrderStatus = OrderStatus::invoiced then begin
                    LogEntry := true;
                    if FleetRockMgt.TryToInsertROStagingRecords(OrderJsonObj, ImportEntryNo, false) and SalesHeaderStaging.Get(ImportEntryNo) then begin
                        SalesHeader.SetCurrentKey("EE Fleetrock ID");
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
                                Success := TryToPostInvoice(SalesHeader);
                            end;
                    end;
                end else
                    if JsonMgt.GetJsonValueAsText(OrderJsonObj, 'status') = 'In Progress' then begin
                        LogEntry := true;
                        if FleetRockMgt.TryToCheckIfAlreadyImported(JsonMgt.GetJsonValueAsText(OrderJsonObj, 'id'), SalesHeader) then
                            Success := FleetRockMgt.TryToInsertROStagingRecords(OrderJsonObj, ImportEntryNo, true);
                    end;
                if LogEntry then
                    FleetRockMgt.InsertImportEntry(Success and (GetLastErrorText() = ''), ImportEntryNo,
                        ImportEntry."Document Type"::"Repair Order", EventType, Enum::"EE Direction"::Import,
                        GetLastErrorText(), URL, 'GET');
            end;
        end;
    end;


    [TryFunction]
    local procedure TryToPostInvoice(var SalesHeader: Record "Sales Header")
    begin
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
    end;
}