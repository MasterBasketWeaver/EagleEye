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
        OrderJsonObj: JsonObject;
        T: JsonToken;
        StartDateTime: DateTime;
        URL, Tags : Text;
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
            Tags := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'tag');
            // if (FleetRockSetup."Import Tag" = '') or Tags.Contains(FleetRockSetup."Import Tag") then begin
            if CheckTagForImport(FleetRockSetup."Import Tag", Tags) then begin
                ImportEntryNo := 0;
                ClearLastError();
                Success := false;
                if IsReceived then begin
                    if JsonMgt.GetJsonValueAsText(OrderJsonObj, 'status') = 'Received' then begin
                        LogEntry := true;
                        if FleetRockMgt.TryToCheckIfAlreadyImported(JsonMgt.GetJsonValueAsText(OrderJsonObj, 'id'), PurchaseHeader) then
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
    end;

    [TryFunction]
    local procedure TryToPostOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);
    end;

    procedure CheckTagForImport(ImportTags: Text; Tags: Text): Boolean
    var
        ImportParts, TagParts : List of [Text];
        i: Integer;
    begin
        if ImportTags = '' then
            exit(true);
        if Tags = '' then
            exit(false);
        ImportTags := ImportTags.ToUpper().Trim();
        Tags := Tags.ToUpper().Trim();
        if ImportTags.Contains('|') then
            ImportParts := ImportTags.Split('|');
        if Tags.Contains(',') then
            TagParts := Tags.Split(',');
        if (ImportParts.Count() = 0) and (TagParts.Count() = 0) then
            exit(ImportTags = Tags);
        for i := 1 to ImportParts.Count() do
            ImportParts.Set(i, ImportParts.Get(i).Trim());
        for i := 1 to TagParts.Count() do
            TagParts.Set(i, TagParts.Get(i).Trim());
        if ImportParts.Count() = 0 then
            exit(TagParts.Contains(ImportTags));
        foreach Tags in TagParts do
            if ImportParts.Contains(Tags) then
                exit(true);
        exit(false);
    end;
}