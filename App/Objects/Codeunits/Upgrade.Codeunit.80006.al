codeunit 80006 "EE Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "EE Import/Export Entry" = RIMD,
    tabledata "EE Sales Header Staging" = RMD,
    tabledata "EE Purch. Header Staging" = RMD,
    tabledata "Sales Invoice Header" = RIMD,
    tabledata "G/L Entry" = RM;


    trigger OnUpgradePerCompany()
    begin
        UpdateData();
    end;

    procedure UpdateData()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GLEntryFleetrockIDsTag) then begin
            PopulateGLEntryFleetrockIDs();
            UpgradeTag.SetUpgradeTag(GLEntryFleetrockIDsTag);
        end;
        // ClearGLSetups();
        // PopulateDocumentNos();
        // ClearInvalidEntries();
        // PopulateFleetrockIDs();
        // ClearPaymentFields();
        // UpdatePurchaseLineDateAddedValues();
    end;

    local procedure PopulateGLEntryFleetrockIDs()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        CopyFleetrockIDToGLEntries(Database::"Sales Invoice Header", SalesInvHeader.FieldNo("No."), SalesInvHeader.FieldNo("Posting Date"), SalesInvHeader.FieldNo("EE Fleetrock ID"));
        CopyFleetrockIDToGLEntries(Database::"Sales Cr.Memo Header", SalesCrMemoHeader.FieldNo("No."), SalesCrMemoHeader.FieldNo("Posting Date"), SalesCrMemoHeader.FieldNo("EE Fleetrock ID"));
        CopyFleetrockIDToGLEntries(Database::"Purch. Inv. Header", PurchInvHeader.FieldNo("No."), PurchInvHeader.FieldNo("Posting Date"), PurchInvHeader.FieldNo("EE Fleetrock ID"));
        CopyFleetrockIDToGLEntries(Database::"Purch. Cr. Memo Hdr.", PurchCrMemoHdr.FieldNo("No."), PurchCrMemoHdr.FieldNo("Posting Date"), PurchCrMemoHdr.FieldNo("EE Fleetrock ID"));
    end;

    // G/L entries only carry the posted document's number and date, so those are
    // the join. Entries posted with an ID are rewritten with the same value:
    // filtering them out needs AddDestinationFilter, which is runtime 17 (BC 28).
    local procedure CopyFleetrockIDToGLEntries(HeaderTableNo: Integer; NoFieldNo: Integer; PostingDateFieldNo: Integer; FleetrockIDFieldNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        DataTrans: DataTransfer;
    begin
        DataTrans.SetTables(HeaderTableNo, Database::"G/L Entry");
        DataTrans.AddSourceFilter(FleetrockIDFieldNo, '<>%1', '');
        DataTrans.AddJoin(NoFieldNo, GLEntry.FieldNo("Document No."));
        DataTrans.AddJoin(PostingDateFieldNo, GLEntry.FieldNo("Posting Date"));
        DataTrans.AddFieldValue(FleetrockIDFieldNo, GLEntry.FieldNo("EE Fleetrock ID"));
        DataTrans.CopyFields();
    end;

    local procedure ClearPaymentFields()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        DataTrans: DataTransfer;
    begin
        DataTrans.SetTables(Database::"Sales Invoice Header", Database::"Sales Invoice Header");
        DataTrans.AddConstantValue(false, SalesInvHeader.FieldNo("EE Sent Payment"));
        DataTrans.AddConstantValue(false, SalesInvHeader.FieldNo("EE No Repair Order On Payment"));
        DataTrans.AddConstantValue(0DT, SalesInvHeader.FieldNo("EE Sent Payment DateTime"));
        DataTrans.CopyFields();
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






    local procedure UpdatePurchaseLineDateAddedValues()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineStaging: Record "EE Purch. Line Staging";
        Values: Dictionary of [Code[20], List of [Text]];
        Dates: List of [Text];
        DateValue, DateFilter : Text;
    begin
        PurchaseHeader.SetFilter("EE Fleetrock ID", '<>%1', '');
        if not PurchaseHeader.FindSet() then
            exit;

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetFilter("EE Part Id", '<>%1', '');
        PurchaseLine.SetFilter("EE Staging Line Entry No.", '<>%1', 0);
        repeat
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            if PurchaseLine.FindSet() then begin
                PurchLineStaging.SetRange("Header id", PurchaseHeader."EE Fleetrock ID");
                repeat
                    PurchLineStaging.SetRange(part_id, PurchaseLine."EE Part Id");
                    if Values.ContainsKey(PurchaseLine."EE Part Id") then begin
                        DateFilter := '';
                        foreach DateValue in Values.Get(PurchaseLine."EE Part Id") do
                            if DateFilter = '' then
                                DateFilter := StrSubstNo('<>%1', DateValue)
                            else
                                DateFilter := StrSubstNo('%1&<>%2', DateFilter, DateValue);
                        PurchLineStaging.SetFilter(date_added, DateFilter);
                    end else
                        PurchLineStaging.SetRange(date_added);
                    if PurchLineStaging.FindLast() then begin
                        PurchaseLine."EE Part Date Added" := PurchLineStaging.date_added;
                        PurchaseLine.Modify(false);
                        if not Values.ContainsKey(PurchaseLine."EE Part Id") then begin
                            Clear(Dates);
                            Dates.Add(PurchLineStaging.date_added);
                            Values.Add(PurchaseLine."EE Part Id", Dates);
                        end else
                            Values.Get(PurchaseLine."EE Part Id").Add(PurchLineStaging.date_added);
                    end;
                until PurchaseLine.Next() = 0;
            end;
            Clear(Values);
        until PurchaseHeader.Next() = 0;
    end;

    var
        GLEntryFleetrockIDsTag: Label 'EE-GL-FLEETROCK-IDS-20261008', Locked = true;
}