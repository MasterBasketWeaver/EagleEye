codeunit 80003 "EE Get Repair Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Fleetrock Import Entry" = r;

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        ImportEntry: Record "EE Fleetrock Import Entry";
        JsonArry: JsonArray;
        T: JsonToken;
        OrderJsonObj: JsonObject;
        JsonVal: JsonValue;
        StartDateTime: DateTime;
        s: Text;
        OrderStatus: Enum "EE Repair Order Status";
        EventType: Enum "EE Event Type";
        EntryNo, ImportEntryNo : Integer;
        CanImport: Boolean;
    begin
        if ImportEntry.FindLast() then
            EntryNo := ImportEntry."Entry No.";

        if Rec."Parameter String" = 'invoiced' then begin
            OrderStatus := OrderStatus::invoiced;
            EventType := EventType::invoiced;
        end else begin
            OrderStatus := OrderStatus::started;
            EventType := EventType::Started;
        end;

        ImportEntry.SetRange(Type, ImportEntry.Type::"Repair Order");
        ImportEntry.SetRange("Event Type", EventType);
        ImportEntry.SetRange(Success, true);
        if ImportEntry.FindLast() then
            StartDateTime := ImportEntry.SystemCreatedAt;

        if not FleetRockMgt.TryToGetRepairOrders(StartDateTime, OrderStatus, JsonArry) then begin
            FleetRockMgt.InsertImportEntry(EntryNo + 1, false, 0, ImportEntry.Type::"Repair Order", EventType, GetLastErrorText());
            exit;
        end;
        if JsonArry.Count() = 0 then
            exit;

        SalesHeader.SetCurrentKey("EE Fleetrock ID");
        foreach T in JsonArry do begin
            OrderJsonObj := T.AsObject();
            OrderJsonObj.Get('id', T);
            JsonVal := T.AsValue();
            s := JsonVal.AsText();
            ImportEntryNo := 0;
            ClearLastError();
            CanImport := FleetRockMgt.TryToCheckIfAlreadyImported(s, SalesHeader);
            if CanImport then
                CanImport := FleetRockMgt.TryToInsertROStagingRecords(OrderJsonObj, ImportEntryNo);
            EntryNo += 1;
            FleetRockMgt.InsertImportEntry(EntryNo, CanImport and (GetLastErrorText() = ''), ImportEntryNo, ImportEntry.Type::"Repair Order", EventType, GetLastErrorText());
        end;
    end;
}