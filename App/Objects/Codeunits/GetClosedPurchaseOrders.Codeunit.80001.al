codeunit 80001 "EE Get Closed Purch. Orders"
{
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Fleetrock Import Entry" = r;


    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        ImportEntry: Record "EE Fleetrock Import Entry";
        JsonArry: JsonArray;
        T: JsonToken;
        OrderJsonObj: JsonObject;
        JsonVal: JsonValue;
        StartDateTime: DateTime;
        s: Text;
        EntryNo, ImportEntryNo : Integer;
        CanImport: Boolean;
    begin
        if ImportEntry.FindLast() then
            EntryNo := ImportEntry."Entry No.";
        ImportEntry.SetRange(Type, ImportEntry.Type::"Purchase Order");
        ImportEntry.SetRange(Success, true);
        if ImportEntry.FindLast() then
            StartDateTime := ImportEntry.SystemCreatedAt;
        if not FleetRockMgt.TryToGetClosedPurchaseOrders(StartDateTime, JsonArry) then begin
            FleetRockMgt.InsertImportEntry(EntryNo + 1, false, 0, ImportEntry.Type::"Purchase Order", GetLastErrorText());
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
            CanImport := FleetRockMgt.TryToCheckIfAlreadyImported(s, PurchaseHeader);
            if CanImport then
                CanImport := FleetRockMgt.TryToInsertPOStagingRecords(OrderJsonObj, ImportEntryNo);
            EntryNo += 1;
            FleetRockMgt.InsertImportEntry(EntryNo, CanImport, ImportEntryNo, ImportEntry.Type::"Purchase Order", GetLastErrorText());
        end;
    end;
}