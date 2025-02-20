codeunit 80001 "EE Get Closed Purch. Order"
{
    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        ImportEntry: Record "EE Fleetrock Import Entry";
        JsonArry: JsonArray;
        T: JsonToken;
        OrderJsonObj: JsonObject;
        JsonVal: JsonValue;
        s: Text;
        EntryNo, ImportEntryNo : Integer;
        CanImport, LoadedData : Boolean;
    begin
        LoadedData := FleetRockMgt.TryToGetPurchaseOrders(Enum::"EE Purch. Order Status"::Closed, JsonArry);
        if (JsonArry.Count() = 0) and LoadedData then
            exit;
        if ImportEntry.FindLast() then
            EntryNo := ImportEntry."Entry No.";
        if not LoadedData then begin
            FleetRockMgt.InsertImportEntry(EntryNo + 1, false, 0, ImportEntry.Type::"Purchase Order", GetLastErrorText());
            exit;
        end;
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
                CanImport := FleetRockMgt.TryToInsertStagingRecords(OrderJsonObj, ImportEntryNo);
            EntryNo += 1;
            FleetRockMgt.InsertImportEntry(EntryNo, CanImport, ImportEntryNo, ImportEntry.Type::"Purchase Order", GetLastErrorText());
        end;
    end;
}