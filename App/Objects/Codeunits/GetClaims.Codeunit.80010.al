codeunit 80010 "EE Get Claims"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = R,
    tabledata "EE Import/Export Entry" = R,
    tabledata "EE Claim Header" = RIMD,
    tabledata "EE Claim Line" = RIMD;

    trigger OnRun()
    var
        ImportEntry: Record "EE Import/Export Entry";
        EventType: Enum "EE Event Type";
        JsonArry: JsonArray;
        StartDateTime: DateTime;
        URL: Text;
    begin
        EventType := Enum::"EE Event Type"::Closed;
        ImportEntry.SetRange("Document Type", ImportEntry."Document Type"::Claim);
        ImportEntry.SetRange("Event Type", EventType);
        ImportEntry.SetRange(Success, true);
        if ImportEntry.FindLast() then
            StartDateTime := ImportEntry.SystemCreatedAt;

        if not FleetRockMgt.TryToGetClaims(StartDateTime, EventType, JsonArry, URL, false) then begin
            FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::Claim,
                EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');
            exit;
        end;

        //TODO
        StartDateTime := 0DT;

        if JsonArry.Count() <> 0 then
            ImportClaims(JsonArry, EventType, URL, StartDateTime);
    end;


    local procedure ImportClaims(var JsonArry: JsonArray; EventType: Enum "EE Event Type"; URL: Text; StartDateTime: DateTime): Boolean
    var
        OrderJsonObj: JsonObject;
        T: JsonToken;
        ImportEntryNo: Integer;
    begin
        foreach T in JsonArry do begin
            OrderJsonObj := T.AsObject();
            if JsonMgt.GetJsonValueAsDateTime(OrderJsonObj, 'date_closed') >= StartDateTime then begin
                ImportEntryNo := 0;
                ClearLastError();
                FleetRockMgt.InsertImportEntry(ImportAsSalesInvoice(OrderJsonObj, ImportEntryNo) and (GetLastErrorText() = ''), ImportEntryNo, Enum::"EE Import Type"::Claim, EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');
            end;
        end;
    end;



    local procedure ImportAsSalesInvoice(var OrderJsonObj: JsonObject; var ImportEntryNo: Integer): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        ClaimHeader: Record "EE Claim Header";
        Success: Boolean;
    begin
        if FleetRockMgt.TryToInsertClaimStagingRecords(OrderJsonObj, ImportEntryNo) and ClaimHeader.Get(ImportEntryNo) then begin
            Success := true;
        end;
        exit(Success);
    end;


    [TryFunction]
    local procedure TryToPostInvoice(var SalesHeader: Record "Sales Header")
    begin
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
    end;



    var
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        GetPurchaseOrders: Codeunit "EE Get Purchase Orders";
        JsonMgt: Codeunit "EE Json Mgt.";
}