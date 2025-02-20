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
        EntryNo, ImportEntryNo : Integer;
        CanImport: Boolean;
    begin
        if ImportEntry.FindLast() then
            EntryNo := ImportEntry."Entry No.";
        ImportEntry.SetRange(Type, ImportEntry.Type::"Repair Order");
        ImportEntry.SetRange(Success, true);
        if ImportEntry.FindLast() then
            StartDateTime := ImportEntry.SystemCreatedAt;

        if Rec."Parameter String" = 'invoiced' then
            OrderStatus := OrderStatus::invoiced;

        if not FleetRockMgt.TryToGetRepairOrders(StartDateTime, OrderStatus, JsonArry) then begin
            FleetRockMgt.InsertImportEntry(EntryNo + 1, false, 0, ImportEntry.Type::"Repair Order", GetLastErrorText());
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
            FleetRockMgt.InsertImportEntry(EntryNo, CanImport, ImportEntryNo, ImportEntry.Type::"Purchase Order", GetLastErrorText());
        end;
    end;
}