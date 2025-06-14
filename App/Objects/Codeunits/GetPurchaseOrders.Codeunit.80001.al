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

        JsonMgt: Codeunit "EE Json Mgt.";
        OrderStatus: Enum "EE Repair Order Status";
        EventType: Enum "EE Event Type";
        JsonArry: JsonArray;
        OrderJsonObj: JsonObject;
        T: JsonToken;
        StartDateTime: DateTime;
        URL, Tags : Text;

        ImportEntryNo: Integer;
        Success, IsReceived, LogEntry : Boolean;
    begin
        if PassedURL = '' then begin
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
        end else begin
            URL := PassedURL;
            if not URL.Contains('event') then
                Error('Invalid URL: %1', URL);
            if URL.Contains('event=Received') then begin
                IsReceived := true;
                EventType := EventType::Received;
            end else begin
                IsReceived := false;
                EventType := EventType::Closed;
            end;
        end;

        if not FleetRockMgt.TryToGetPurchaseOrders(StartDateTime, JsonArry, URL, EventType) then begin
            FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::"Purchase Order",
                EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');
            exit;
        end;
        if JsonArry.Count() = 0 then begin
            if (PassedURL <> '') and GuiAllowed() then begin
                JsonArry.WriteTo(Tags);
                if not Confirm('Empty array:\%1\\%2', false, URL, Tags) then;
            end;
            exit;
        end;
        FleetRockSetup.Get();
        PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
        LogEntry := not IsReceived;
        foreach T in JsonArry do begin
            OrderJsonObj := T.AsObject();
            Tags := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'tag');
            if CheckTagForImport(FleetRockSetup."Import Tags", Tags) then begin
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
                    if FleetRockMgt.TryToInsertPOStagingRecords(OrderJsonObj, ImportEntryNo, false) and PurchaseHeaderStaging.Get(ImportEntryNo) then
                        Success := UpdateAndPostPurchaseOrder(FleetrockSetup, PurchaseHeaderStaging);
                end;
                if LogEntry then
                    FleetRockMgt.InsertImportEntry(Success and (GetLastErrorText() = ''), ImportEntryNo,
                        ImportEntry."Document Type"::"Purchase Order", EventType, Enum::"EE Direction"::Import,
                        GetLastErrorText(), URL, 'GET');
            end;
        end;
    end;

    procedure UpdateAndPostPurchaseOrder(var FleetrockSetup: Record "EE Fleetrock Setup"; var PurchaseHeaderStaging: Record "EE Purch. Header Staging"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        DocNo: Code[20];
        Success: Boolean;
    begin
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
        exit(Success);
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

    procedure SetURL(NewURL: Text)
    begin
        PassedURL := NewURL;
    end;

    var
        FleetRockMgt: Codeunit "EE Fleetrock Mgt.";
        PassedURL: Text;
}