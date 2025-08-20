codeunit 80006 "EE Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "EE Import/Export Entry" = RIMD,
    tabledata "EE Sales Header Staging" = RMD,
    tabledata "EE Purch. Header Staging" = RMD;


    trigger OnUpgradePerCompany()
    begin
        UpdateData();
    end;

    procedure UpdateData()
    begin
        // ClearGLSetups();
        // PopulateDocumentNos();
        // ClearInvalidEntries();

        PopulateFleetrockIDs();
    end;


    local procedure PopulateFleetrockIDs()
    var
        FleetrockEntry: Record "EE Import/Export Entry";
        SalesHeaderStaging: Record "EE Sales Header Staging";
        PurchHeaderStaging: Record "EE Purch. Header Staging";
    begin
        FleetrockEntry.SetFilter("Import Entry No.", '<>%1', 0);
        FleetrockEntry.SetRange("Fleetrock ID", '');
        FleetrockEntry.SetRange("Document Type", FleetrockEntry."Document Type"::"Purchase Order");
        if FleetrockEntry.FindSet() then
            repeat
                if PurchHeaderStaging.Get(FleetrockEntry."Import Entry No.") then begin
                    FleetrockEntry."Fleetrock ID" := PurchHeaderStaging.id;
                    FleetrockEntry.Modify(false);
                end;
            until FleetrockEntry.Next() = 0;
        FleetrockEntry.SetRange("Document Type", FleetrockEntry."Document Type"::"Repair Order");
        if FleetrockEntry.FindSet() then
            repeat
                if SalesHeaderStaging.Get(FleetrockEntry."Import Entry No.") then begin
                    FleetrockEntry."Fleetrock ID" := SalesHeaderStaging.id;
                    FleetrockEntry.Modify(false);
                end;
            until FleetrockEntry.Next() = 0;
    end;

    local procedure ClearInvalidEntries()
    var
        FleetrockEntry: Record "EE Import/Export Entry";
        StagedPurchHeader: Record "EE Purch. Header Staging";
    begin
        if CompanyName <> 'Test - Diesel Repair Shop' then
            exit;
        FleetrockEntry.SetRange("Entry No.", 12898, 12997);
        FleetrockEntry.SetRange("Document Type", FleetrockEntry."Document Type"::"Purchase Order");
        FleetrockEntry.SetRange(Success, false);
        FleetrockEntry.SetRange("Document No.", '');
        if FleetrockEntry.FindSet() then
            repeat
                if StagedPurchHeader.Get(FleetrockEntry."Import Entry No.") then
                    StagedPurchHeader.Delete(true);
                FleetrockEntry.Delete(true);
            until FleetrockEntry.Next() = 0;
    end;

    local procedure PopulateDocumentNos()
    var
        ImportExportEntry: Record "EE Import/Export Entry";
        PurchHeaderStaging: Record "EE Purch. Header Staging";
        SalesHeaderStaging: Record "EE Sales Header Staging";
    begin
        ImportExportEntry.SetFilter("Document No.", '<>%1', '');
        if not ImportExportEntry.IsEmpty() then
            exit;

        ImportExportEntry.SetRange("Document No.", '');
        ImportExportEntry.SetFilter("Import Entry No.", '<>%1', 0);
        ImportExportEntry.SetRange("Document Type", ImportExportEntry."Document Type"::"Repair Order");
        if ImportExportEntry.FindSet() then
            repeat
                if SalesHeaderStaging.Get(ImportExportEntry."Import Entry No.") then begin
                    ImportExportEntry."Document No." := SalesHeaderStaging."Document No.";
                    ImportExportEntry.Modify(false);
                end;
            until ImportExportEntry.Next() = 0;
        ImportExportEntry.SetRange("Document Type", ImportExportEntry."Document Type"::"Purchase Order");
        if ImportExportEntry.FindSet() then
            repeat
                if PurchHeaderStaging.Get(ImportExportEntry."Import Entry No.") then begin
                    ImportExportEntry."Document No." := PurchHeaderStaging."Document No.";
                    ImportExportEntry.Modify(false);
                end;
            until ImportExportEntry.Next() = 0;
    end;


    local procedure ClearGLSetups()
    var
        Item: Record "Item";
        FleetrockSetup: Record "EE Fleetrock Setup";
    begin
        if not FleetrockSetup.Get() then
            exit;
        if not Item.Get(FleetrockSetup."Purchase Item No.") then
            FleetrockSetup."Purchase Item No." := '';
        if not Item.Get(FleetrockSetup."Internal Labor Item No.") then
            FleetrockSetup."Internal Labor Item No." := '';
        if not Item.Get(FleetrockSetup."External Labor Item No.") then
            FleetrockSetup."External Labor Item No." := '';
        if not Item.Get(FleetrockSetup."Internal Parts Item No.") then
            FleetrockSetup."Internal Parts Item No." := '';
        if not Item.Get(FleetrockSetup."External Parts Item No.") then
            FleetrockSetup."External Parts Item No." := '';
        FleetrockSetup.Modify(false);
    end;


    local procedure ClearImportEntries()
    var
        ImportExportEntry: Record "EE Import/Export Entry";
    begin
        ImportExportEntry.SetRange(Direction, ImportExportEntry.Direction::Import);
        ImportExportEntry.SetRange("Document Type", ImportExportEntry."Document Type"::"Repair Order");
        ImportExportEntry.SetRange(Success, false);
        ImportExportEntry.SetRange("Error Message", '');
        ImportExportEntry.SetRange("Import Entry No.", 0);
        ImportExportEntry.DeleteAll(true);
    end;
}