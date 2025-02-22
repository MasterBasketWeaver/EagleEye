codeunit 80001 "EE Get Closed Purch. Orders"
{
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Import/Export Entry" = r;


    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        ImportEntry: Record "EE Import/Export Entry";
        JsonArry: JsonArray;
        T: JsonToken;
        OrderJsonObj: JsonObject;
        JsonVal: JsonValue;
        StartDateTime: DateTime;
        URL, s : Text;
        EntryNo, ImportEntryNo : Integer;
        CanImport: Boolean;
    begin
        if ImportEntry.FindLast() then
            EntryNo := ImportEntry."Entry No.";
        ImportEntry.SetRange("Document Type", ImportEntry."Document Type"::"Purchase Order");
        ImportEntry.SetRange(Success, true);
        if ImportEntry.FindLast() then
            StartDateTime := ImportEntry.SystemCreatedAt;
        if not FleetRockMgt.TryToGetClosedPurchaseOrders(StartDateTime, JsonArry, URL) then begin
            FleetRockMgt.InsertImportEntry(EntryNo + 1, false, 0, ImportEntry."Document Type"::"Purchase Order",
                Enum::"EE Event Type"::Closed, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');
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
            FleetRockMgt.InsertImportEntry(EntryNo, CanImport and (GetLastErrorText() = ''), ImportEntryNo,
                ImportEntry."Document Type"::"Purchase Order", Enum::"EE Event Type"::Closed, Enum::"EE Direction"::Import,
                GetLastErrorText(), URL, 'GET');
        end;
    end;
}