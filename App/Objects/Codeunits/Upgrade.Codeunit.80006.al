codeunit 80006 "EE Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "EE Import/Export Entry" = RIMD,
    tabledata "EE Sales Header Staging" = RMD,
    tabledata "EE Purch. Header Staging" = RMD,
    tabledata "Sales Invoice Header" = RIMD,
    tabledata "G/L Entry" = RM,
    tabledata "Cust. Ledger Entry" = RM,
    tabledata "Vendor Ledger Entry" = RM,
    tabledata "Detailed Cust. Ledg. Entry" = RM,
    tabledata "Detailed Vendor Ledg. Entry" = RM,
    tabledata "VAT Entry" = RM,
    tabledata "Bank Account Ledger Entry" = RM,
    tabledata "Item Ledger Entry" = RM,
    tabledata "Value Entry" = RM;


    trigger OnUpgradePerCompany()
    begin
        UpdateData();
    end;

    procedure UpdateData()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(LedgerEntryFleetrockIDsTag) then begin
            PopulateLedgerEntryFleetrockIDs();
            UpgradeTag.SetUpgradeTag(LedgerEntryFleetrockIDsTag);
        end;
        // ClearGLSetups();
        // PopulateDocumentNos();
        // ClearInvalidEntries();
        // PopulateFleetrockIDs();
        // PopulatePaidEntryDetails();
        // ClearPaymentFields();
        // UpdatePurchaseLineDateAddedValues();
    end;

    procedure PopulateLedgerEntryFleetrockIDs()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PopulateSalesEntryFleetrockIDs(Database::"Sales Invoice Header", SalesInvHeader.FieldNo("No."), SalesInvHeader.FieldNo("Posting Date"), SalesInvHeader.FieldNo("EE Fleetrock ID"));
        PopulateSalesEntryFleetrockIDs(Database::"Sales Cr.Memo Header", SalesCrMemoHeader.FieldNo("No."), SalesCrMemoHeader.FieldNo("Posting Date"), SalesCrMemoHeader.FieldNo("EE Fleetrock ID"));
        PopulatePurchaseEntryFleetrockIDs(Database::"Purch. Inv. Header", PurchInvHeader.FieldNo("No."), PurchInvHeader.FieldNo("Posting Date"), PurchInvHeader.FieldNo("EE Fleetrock ID"));
        PopulatePurchaseEntryFleetrockIDs(Database::"Purch. Cr. Memo Hdr.", PurchCrMemoHdr.FieldNo("No."), PurchCrMemoHdr.FieldNo("Posting Date"), PurchCrMemoHdr.FieldNo("EE Fleetrock ID"));
        PopulateItemLedgerEntryFleetrockIDs();
    end;

    local procedure PopulateSalesEntryFleetrockIDs(HeaderTableNo: Integer; NoFieldNo: Integer; PostingDateFieldNo: Integer; FleetrockIDFieldNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        PopulateCommonEntryFleetrockIDs(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo);
        CopyFleetrockIDFromHeader(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo,
            Database::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Document No."), CustLedgerEntry.FieldNo("Posting Date"), CustLedgerEntry.FieldNo("EE Fleetrock ID"));
        CopyFleetrockIDFromHeader(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo,
            Database::"Detailed Cust. Ledg. Entry", DtldCustLedgEntry.FieldNo("Document No."), DtldCustLedgEntry.FieldNo("Posting Date"), DtldCustLedgEntry.FieldNo("EE Fleetrock ID"));
    end;

    local procedure PopulatePurchaseEntryFleetrockIDs(HeaderTableNo: Integer; NoFieldNo: Integer; PostingDateFieldNo: Integer; FleetrockIDFieldNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        PopulateCommonEntryFleetrockIDs(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo);
        CopyFleetrockIDFromHeader(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo,
            Database::"Vendor Ledger Entry", VendorLedgerEntry.FieldNo("Document No."), VendorLedgerEntry.FieldNo("Posting Date"), VendorLedgerEntry.FieldNo("EE Fleetrock ID"));
        CopyFleetrockIDFromHeader(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo,
            Database::"Detailed Vendor Ledg. Entry", DtldVendorLedgEntry.FieldNo("Document No."), DtldVendorLedgEntry.FieldNo("Posting Date"), DtldVendorLedgEntry.FieldNo("EE Fleetrock ID"));
    end;

    local procedure PopulateCommonEntryFleetrockIDs(HeaderTableNo: Integer; NoFieldNo: Integer; PostingDateFieldNo: Integer; FleetrockIDFieldNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        CopyFleetrockIDFromHeader(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo,
            Database::"G/L Entry", GLEntry.FieldNo("Document No."), GLEntry.FieldNo("Posting Date"), GLEntry.FieldNo("EE Fleetrock ID"));
        CopyFleetrockIDFromHeader(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo,
            Database::"VAT Entry", VATEntry.FieldNo("Document No."), VATEntry.FieldNo("Posting Date"), VATEntry.FieldNo("EE Fleetrock ID"));
        CopyFleetrockIDFromHeader(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo,
            Database::"Bank Account Ledger Entry", BankAccountLedgerEntry.FieldNo("Document No."), BankAccountLedgerEntry.FieldNo("Posting Date"), BankAccountLedgerEntry.FieldNo("EE Fleetrock ID"));
        CopyFleetrockIDFromHeader(HeaderTableNo, NoFieldNo, PostingDateFieldNo, FleetrockIDFieldNo,
            Database::"Value Entry", ValueEntry.FieldNo("Document No."), ValueEntry.FieldNo("Posting Date"), ValueEntry.FieldNo("EE Fleetrock ID"));
    end;

    // Entries only carry the posted document's number and date, so those are the
    // join. Entries posted with an ID are rewritten with the same value: filtering
    // them out needs AddDestinationFilter, which is runtime 17 (BC 28).
    local procedure CopyFleetrockIDFromHeader(HeaderTableNo: Integer; NoFieldNo: Integer; PostingDateFieldNo: Integer; FleetrockIDFieldNo: Integer; EntryTableNo: Integer; DocumentNoFieldNo: Integer; EntryPostingDateFieldNo: Integer; EntryFleetrockIDFieldNo: Integer)
    var
        DataTrans: DataTransfer;
    begin
        DataTrans.SetTables(HeaderTableNo, EntryTableNo);
        DataTrans.AddSourceFilter(FleetrockIDFieldNo, '<>%1', '');
        DataTrans.AddJoin(NoFieldNo, DocumentNoFieldNo);
        DataTrans.AddJoin(PostingDateFieldNo, EntryPostingDateFieldNo);
        DataTrans.AddFieldValue(FleetrockIDFieldNo, EntryFleetrockIDFieldNo);
        DataTrans.CopyFields();
    end;

    // Item ledger entries carry the shipment/receipt number rather than the
    // invoice's, so they take the ID from their invoice value entries. Item charge
    // value entries are skipped: they belong to a different invoice.
    local procedure PopulateItemLedgerEntryFleetrockIDs()
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DataTrans: DataTransfer;
    begin
        DataTrans.SetTables(Database::"Value Entry", Database::"Item Ledger Entry");
        DataTrans.AddSourceFilter(ValueEntry.FieldNo("EE Fleetrock ID"), '<>%1', '');
        DataTrans.AddSourceFilter(ValueEntry.FieldNo("Item Charge No."), '%1', '');
        DataTrans.AddJoin(ValueEntry.FieldNo("Item Ledger Entry No."), ItemLedgerEntry.FieldNo("Entry No."));
        DataTrans.AddFieldValue(ValueEntry.FieldNo("EE Fleetrock ID"), ItemLedgerEntry.FieldNo("EE Fleetrock ID"));
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



    local procedure PopulatePaidEntryDetails()
    var
        ImportExportEntry: Record "EE Import/Export Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        FleetrockID: Text;
        i, i2 : Integer;
    begin
        ImportExportEntry.SetRange("Fleetrock ID", '');
        ImportExportEntry.SetRange("Document Type", ImportExportEntry."Document Type"::"Repair Order");
        ImportExportEntry.SetRange(URL, 'https://www.fleetrock.com/API/UpdateRO?token=71e18abf-f5b4-41f0-ac9c-adef156d3377');
        ImportExportEntry.SetFilter("Request Body", StrSubstNo('*%1*', '"ro_id":"'));
        if not ImportExportEntry.FindSet() then
            exit;

        SalesInvHeader.SetCurrentKey("EE Fleetrock ID");
        repeat
            i := ImportExportEntry."Request Body".IndexOf('"ro_id":"') + StrLen('"ro_id":"');
            i2 := ImportExportEntry."Request Body".IndexOf('","date_invoice_paid":');
            FleetrockID := CopyStr(ImportExportEntry."Request Body", i, i2 - i);
            ImportExportEntry."Fleetrock ID" := FleetrockID;
            SalesInvHeader.SetRange("EE Fleetrock ID", FleetrockID);
            if SalesInvHeader.FindFirst() then
                ImportExportEntry."Document No." := SalesInvHeader."No.";
            ImportExportEntry.Modify(false);
        until ImportExportEntry.Next() = 0;
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
        LedgerEntryFleetrockIDsTag: Label 'EE-LEDGER-FLEETROCK-IDS-20261008', Locked = true;
}