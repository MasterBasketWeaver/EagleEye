codeunit 80001 "EE Get Purchase Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Import/Export Entry" = r;


    trigger OnRun()
    var
        PurchaseHeaderStaging: Record "EE Purch. Header Staging";
        ImportEntry: Record "EE Import/Export Entry";
        EventType: Enum "EE Event Type";
        JsonArry: JsonArray;
        StartDateTime: DateTime;
        URL: Text;
        Success, IsReceived, LogEntry : Boolean;
    begin
        if PassedURL = '' then begin
            if Rec."Parameter String" = 'received' then begin
                IsReceived := true;
                EventType := EventType::Received
            end else begin
                EventType := EventType::Closed;
                CheckToWaitForOtherJobQueue(Rec);
            end;

            ImportEntry.SetRange("Document Type", ImportEntry."Document Type"::"Purchase Order");
            ImportEntry.SetRange(Success, true);
            ImportEntry.SetRange("Event Type", EventType);
            if ImportEntry.FindLast() then
                StartDateTime := ImportEntry.SystemCreatedAt;
        end else begin
            URL := PassedURL;
            // if not URL.Contains('event') then
            //     Error('Invalid URL: %1', URL);
            if URL.Contains('event=Received') then begin
                IsReceived := true;
                EventType := EventType::Received;
            end else
                EventType := EventType::Closed;
        end;

        if not FleetRockMgt.TryToGetPurchaseOrders(StartDateTime, JsonArry, URL, EventType) then begin
            FleetRockMgt.InsertImportEntry(false, 0, ImportEntry."Document Type"::"Purchase Order",
                EventType, Enum::"EE Direction"::Import, GetLastErrorText(), URL, 'GET');
            exit;
        end;
        if JsonArry.Count() > 0 then
            ImportPurchaseOrders(JsonArry, EventType, URL, IsReceived);
    end;

    procedure ImportPurchaseOrders(var JsonArry: JsonArray; EventType: Enum "EE Event Type"; URL: Text; IsReceived: Boolean): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        ImportEntry: Record "EE Import/Export Entry";
        PurchaseHeaderStaging: Record "EE Purch. Header Staging";
        FleetRockSetup: Record "EE Fleetrock Setup";
        OrderJsonObj: JsonObject;
        T: JsonToken;
        Tags: Text;
        ImportEntryNo: Integer;
        Success, LogEntry : Boolean;
    begin
        FleetRockSetup.Get();
        PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
        foreach T in JsonArry do begin
            OrderJsonObj := T.AsObject();
            Tags := JsonMgt.GetJsonValueAsText(OrderJsonObj, 'tag');
            if CheckTagForImport(FleetRockSetup."Import Tags", Tags) then begin
                ImportEntryNo := 0;
                ClearLastError();
                Success := false;
                LogEntry := false;
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

    local procedure CheckToWaitForOtherJobQueue(var Rec: Record "Job Queue Entry")
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        StartTime: DateTime;
        TimeoutLength: Integer;
    begin
        JobQueueEntry.SetFilter(ID, '<>%1', Rec.ID);
        JobQueueEntry.SetRange("Object Type to Run", Rec."Object Type to Run");
        JobQueueEntry.SetRange("Object ID to Run", Rec."Object ID to Run");
        JobQueueEntry.SetRange("Parameter String", 'received');
        if not JobQueueEntry.FindFirst() then
            exit;

        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.SetRange("Object Type to Run", Rec."Object Type to Run");
        JobQueueLogEntry.SetRange("Object ID to Run", Rec."Object ID to Run");
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::"In Process");
        if JobQueueLogEntry.IsEmpty() then
            exit;

        TimeoutLength := Rec."No. of Minutes between Runs" * 2 * 60000; // Convert minutes to milliseconds, double the timeout between runs.
        StartTime := CurrentDateTime();
        while not JobQueueLogEntry.IsEmpty() do begin
            if CurrentDateTime() - StartTime > TimeoutLength then
                Error('Timeout waiting for other job queue entry %1 to finish.', JobQueueEntry.ID);
            Sleep(5000);
        end;
    end;

    procedure UpdateAndPostPurchaseOrder(var FleetrockSetup: Record "EE Fleetrock Setup"; var PurchaseHeaderStaging: Record "EE Purch. Header Staging"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";

        DocNo: Code[20];
        Success: Boolean;
    begin
        PurchaseHeader.SetCurrentKey("EE Fleetrock ID");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
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
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetFilter(Quantity, '<%1', 0);
        if PurchaseLine.FindFirst() then
            Error('Cannot post Purchase Order %1 because line %2 has a negative quantity: %3.', PurchaseHeader."No.", PurchaseLine."Line No.", PurchaseLine.Quantity);
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
        JsonMgt: Codeunit "EE Json Mgt.";
        PassedURL: Text;
}