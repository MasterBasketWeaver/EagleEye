codeunit 80006 "EE Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "EE Import/Export Entry" = RIMD;

    trigger OnUpgradePerCompany()
    begin
        // UpdateData();
    end;

    procedure UpdateData()
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