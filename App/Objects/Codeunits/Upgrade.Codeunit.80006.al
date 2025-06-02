codeunit 80006 "EE Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "EE Import/Export Entry" = RIMD,
    tabledata "EE Sales Header Staging" = RM,
    tabledata "EE Purch. Header Staging" = RM;


    trigger OnUpgradePerCompany()
    begin
        UpdateData();
    end;

    procedure UpdateData()
    begin
        // ClearGLSetups();
        // PopulateDocumentNos();
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