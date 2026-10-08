codeunit 80150 "EE Fleetrock ID Posting Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        RevenueAccountNo: Code[20];
        ExpenseAccountNo: Code[20];
        InventoryAccountNo: Code[20];
        COGSAccountNo: Code[20];
        PaymentMethodCode: Code[10];
        IsInitialized: Boolean;
        TestCodeTok: Label 'FRTEST', Locked = true;

    [Test]
    procedure SalesInvoiceGLLinesCarryFleetrockID()
    var
        SalesHeader: Record "Sales Header";
        PostedNo: Code[20];
    begin
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, 'FRTEST-S001');
        AddSalesLine(SalesHeader, Enum::"Sales Line Type"::"G/L Account", RevenueAccountNo, 1, 100);
        AddSalesLine(SalesHeader, Enum::"Sales Line Type"::"G/L Account", RevenueAccountNo, 2, 40);

        PostedNo := PostSalesInvoice(SalesHeader);

        VerifyGLEntries(PostedNo, 'FRTEST-S001');
    end;

    [Test]
    procedure SalesInvoiceItemLineCarriesFleetrockIDToCostGLEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PostedNo: Code[20];
    begin
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, 'FRTEST-STOCK');
        AddPurchaseLine(PurchaseHeader, Enum::"Purchase Line Type"::Item, Item."No.", 5, 20);
        PostPurchaseOrder(PurchaseHeader);

        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, 'FRTEST-S002');
        AddSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, Item."No.", 2, 75);

        PostedNo := PostSalesInvoice(SalesHeader);

        VerifyGLEntries(PostedNo, 'FRTEST-S002');
        VerifyGLAccountPosted(PostedNo, COGSAccountNo);
        VerifyGLAccountPosted(PostedNo, InventoryAccountNo);
    end;

    [Test]
    procedure PurchaseOrderCarriesFleetrockID()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedNo: Code[20];
    begin
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, 'FRTEST-P001');
        AddPurchaseLine(PurchaseHeader, Enum::"Purchase Line Type"::"G/L Account", ExpenseAccountNo, 1, 250);
        AddPurchaseLine(PurchaseHeader, Enum::"Purchase Line Type"::Item, Item."No.", 3, 15);

        PostedNo := PostPurchaseOrder(PurchaseHeader);

        VerifyGLEntries(PostedNo, 'FRTEST-P001');
        VerifyGLAccountPosted(PostedNo, InventoryAccountNo);
    end;

    [Test]
    procedure SalesCreditMemoCarriesFleetrockID()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 'FRTEST-SCM1');
        AddSalesLine(SalesHeader, Enum::"Sales Line Type"::"G/L Account", RevenueAccountNo, 1, 60);

        PostSalesDocument(SalesHeader);
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesCrMemoHeader.FindFirst();

        VerifyGLEntries(SalesCrMemoHeader."No.", 'FRTEST-SCM1');
    end;

    [Test]
    procedure PurchaseCreditMemoCarriesFleetrockID()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", 'FRTEST-PCM1');
        AddPurchaseLine(PurchaseHeader, Enum::"Purchase Line Type"::"G/L Account", ExpenseAccountNo, 1, 80);

        PurchaseHeader.Invoice := true;
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);
        PurchCrMemoHdr.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchCrMemoHdr.FindFirst();

        VerifyGLEntries(PurchCrMemoHdr."No.", 'FRTEST-PCM1');
    end;

    // Posts a document with an ID first so a value left behind on a journal line
    // or in a single-instance codeunit would show up on the second posting.
    [Test]
    procedure DocumentWithoutFleetrockIDLeavesEntriesBlank()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PostedNo: Code[20];
    begin
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, 'FRTEST-S003');
        AddSalesLine(SalesHeader, Enum::"Sales Line Type"::"G/L Account", RevenueAccountNo, 1, 10);
        PostSalesInvoice(SalesHeader);

        Clear(SalesHeader);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        AddSalesLine(SalesHeader, Enum::"Sales Line Type"::"G/L Account", RevenueAccountNo, 1, 20);
        PostedNo := PostSalesInvoice(SalesHeader);

        VerifyGLEntries(PostedNo, '');

        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        AddPurchaseLine(PurchaseHeader, Enum::"Purchase Line Type"::Item, Item."No.", 1, 15);
        PostedNo := PostPurchaseOrder(PurchaseHeader);

        VerifyGLEntries(PostedNo, '');
    end;

    [Test]
    procedure SalesInvoiceWithBalancingPaymentCarriesFleetrockID()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedNo: Code[20];
    begin
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, 'FRTEST-S004');
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Modify(true);
        AddSalesLine(SalesHeader, Enum::"Sales Line Type"::"G/L Account", RevenueAccountNo, 1, 300);

        PostedNo := PostSalesInvoice(SalesHeader);

        CustLedgerEntry.SetRange("Document No.", PostedNo);
        if CustLedgerEntry.Count() <> 2 then
            Error('Expected an invoice and a balancing payment customer ledger entry for %1, found %2.', PostedNo, CustLedgerEntry.Count());
        VerifyGLEntries(PostedNo, 'FRTEST-S004');
    end;

    // DataTransfer only runs in upgrade/install code, so the backfill can't be
    // called from a test; this checks what it left in the company's real data.
    [Test]
    procedure PostedDocumentGLEntriesCarryTheirFleetrockID()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        VerifyPostedDocumentGLEntries(Database::"Sales Invoice Header", SalesInvHeader.FieldNo("No."), SalesInvHeader.FieldNo("Posting Date"), SalesInvHeader.FieldNo("EE Fleetrock ID"));
        VerifyPostedDocumentGLEntries(Database::"Sales Cr.Memo Header", SalesCrMemoHeader.FieldNo("No."), SalesCrMemoHeader.FieldNo("Posting Date"), SalesCrMemoHeader.FieldNo("EE Fleetrock ID"));
        VerifyPostedDocumentGLEntries(Database::"Purch. Inv. Header", PurchInvHeader.FieldNo("No."), PurchInvHeader.FieldNo("Posting Date"), PurchInvHeader.FieldNo("EE Fleetrock ID"));
        VerifyPostedDocumentGLEntries(Database::"Purch. Cr. Memo Hdr.", PurchCrMemoHdr.FieldNo("No."), PurchCrMemoHdr.FieldNo("Posting Date"), PurchCrMemoHdr.FieldNo("EE Fleetrock ID"));
    end;

    local procedure Initialize()
    var
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        InventorySetup: Record "Inventory Setup";
        WarehouseSetup: Record "Warehouse Setup";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        BankAccount: Record "Bank Account";
        PaymentMethod: Record "Payment Method";
        ReceivablesAccountNo: Code[20];
        PayablesAccountNo: Code[20];
        RoundingAccountNo: Code[20];
        VATAccountNo: Code[20];
        BankGLAccountNo: Code[20];
    begin
        if IsInitialized then
            exit;

        // The test runner rolls all of this back when the codeunit finishes.
        GLSetup.Get();
        GLSetup."Allow Posting From" := 0D;
        GLSetup."Allow Posting To" := 0D;
        GLSetup."Journal Templ. Name Mandatory" := false;
        GLSetup.Modify();
        if UserSetup.Get(UserId()) then begin
            UserSetup."Allow Posting From" := 0D;
            UserSetup."Allow Posting To" := 0D;
            UserSetup.Modify();
        end;

        SalesSetup.Get();
        SalesSetup."Invoice Nos." := CreateNoSeries('SI');
        SalesSetup."Posted Invoice Nos." := CreateNoSeries('PSI');
        SalesSetup."Credit Memo Nos." := CreateNoSeries('SCM');
        SalesSetup."Posted Credit Memo Nos." := CreateNoSeries('PSCM');
        SalesSetup."Order Nos." := CreateNoSeries('SO');
        SalesSetup."Posted Shipment Nos." := CreateNoSeries('SHP');
        SalesSetup."Posted Return Receipt Nos." := CreateNoSeries('SRR');
        SalesSetup."Shipment on Invoice" := false;
        SalesSetup."Return Receipt on Credit Memo" := false;
        SalesSetup."Ext. Doc. No. Mandatory" := false;
        SalesSetup."Credit Warnings" := SalesSetup."Credit Warnings"::"No Warning";
        SalesSetup."Stockout Warning" := false;
        SalesSetup."Invoice Rounding" := false;
        SalesSetup.Modify();

        PurchSetup.Get();
        PurchSetup."Order Nos." := CreateNoSeries('PO');
        PurchSetup."Invoice Nos." := CreateNoSeries('PI');
        PurchSetup."Posted Invoice Nos." := CreateNoSeries('PPI');
        PurchSetup."Credit Memo Nos." := CreateNoSeries('PCM');
        PurchSetup."Posted Credit Memo Nos." := CreateNoSeries('PPCM');
        PurchSetup."Posted Receipt Nos." := CreateNoSeries('RCP');
        PurchSetup."Posted Return Shpt. Nos." := CreateNoSeries('PRS');
        PurchSetup."Return Shipment on Credit Memo" := false;
        PurchSetup."Invoice Rounding" := false;
        PurchSetup.Modify();

        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := true;
        InventorySetup."Expected Cost Posting to G/L" := false;
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Never;
        InventorySetup."Prevent Negative Inventory" := false;
        InventorySetup."Location Mandatory" := false;
        InventorySetup.Modify();

        if WarehouseSetup.Get() then begin
            WarehouseSetup."Require Receive" := false;
            WarehouseSetup."Require Shipment" := false;
            WarehouseSetup."Require Pick" := false;
            WarehouseSetup."Require Put-away" := false;
            WarehouseSetup.Modify();
        end;

        GenBusPostingGroup.Code := TestCodeTok;
        GenBusPostingGroup."Def. VAT Bus. Posting Group" := TestCodeTok;
        GenBusPostingGroup.Insert();
        GenProdPostingGroup.Code := TestCodeTok;
        GenProdPostingGroup."Def. VAT Prod. Posting Group" := TestCodeTok;
        GenProdPostingGroup.Insert();
        VATBusPostingGroup.Code := TestCodeTok;
        VATBusPostingGroup.Insert();
        VATProdPostingGroup.Code := TestCodeTok;
        VATProdPostingGroup.Insert();

        RevenueAccountNo := CreateGLAccount('REV');
        ExpenseAccountNo := CreateGLAccount('EXP');
        InventoryAccountNo := CreateGLAccount('INV');
        COGSAccountNo := CreateGLAccount('COGS');
        ReceivablesAccountNo := CreateGLAccount('AR');
        PayablesAccountNo := CreateGLAccount('AP');
        RoundingAccountNo := CreateGLAccount('RND');
        VATAccountNo := CreateGLAccount('VAT');
        BankGLAccountNo := CreateGLAccount('BANK');

        VATPostingSetup."VAT Bus. Posting Group" := TestCodeTok;
        VATPostingSetup."VAT Prod. Posting Group" := TestCodeTok;
        VATPostingSetup."VAT Identifier" := TestCodeTok;
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Purchase VAT Account" := VATAccountNo;
        VATPostingSetup."Sales VAT Account" := VATAccountNo;
        VATPostingSetup.Insert();

        GeneralPostingSetup."Gen. Bus. Posting Group" := TestCodeTok;
        GeneralPostingSetup."Gen. Prod. Posting Group" := TestCodeTok;
        GeneralPostingSetup."Sales Account" := RevenueAccountNo;
        GeneralPostingSetup."Sales Credit Memo Account" := RevenueAccountNo;
        GeneralPostingSetup."Sales Line Disc. Account" := RevenueAccountNo;
        GeneralPostingSetup."Sales Inv. Disc. Account" := RevenueAccountNo;
        GeneralPostingSetup."COGS Account" := COGSAccountNo;
        GeneralPostingSetup."COGS Account (Interim)" := COGSAccountNo;
        GeneralPostingSetup."Inventory Adjmt. Account" := COGSAccountNo;
        GeneralPostingSetup."Purch. Account" := ExpenseAccountNo;
        GeneralPostingSetup."Purch. Credit Memo Account" := ExpenseAccountNo;
        GeneralPostingSetup."Purch. Line Disc. Account" := ExpenseAccountNo;
        GeneralPostingSetup."Purch. Inv. Disc. Account" := ExpenseAccountNo;
        GeneralPostingSetup."Direct Cost Applied Account" := ExpenseAccountNo;
        GeneralPostingSetup."Overhead Applied Account" := ExpenseAccountNo;
        GeneralPostingSetup."Purchase Variance Account" := ExpenseAccountNo;
        GeneralPostingSetup.Insert();

        CustomerPostingGroup.Code := TestCodeTok;
        CustomerPostingGroup."Receivables Account" := ReceivablesAccountNo;
        CustomerPostingGroup."Invoice Rounding Account" := RoundingAccountNo;
        CustomerPostingGroup.Insert();

        VendorPostingGroup.Code := TestCodeTok;
        VendorPostingGroup."Payables Account" := PayablesAccountNo;
        VendorPostingGroup."Invoice Rounding Account" := RoundingAccountNo;
        VendorPostingGroup.Insert();

        InventoryPostingGroup.Code := TestCodeTok;
        InventoryPostingGroup.Insert();
        InventoryPostingSetup."Location Code" := '';
        InventoryPostingSetup."Invt. Posting Group Code" := TestCodeTok;
        InventoryPostingSetup."Inventory Account" := InventoryAccountNo;
        InventoryPostingSetup."Inventory Account (Interim)" := InventoryAccountNo;
        InventoryPostingSetup.Insert();

        BankAccountPostingGroup.Code := TestCodeTok;
        BankAccountPostingGroup."G/L Account No." := BankGLAccountNo;
        BankAccountPostingGroup.Insert();
        BankAccount.Init();
        BankAccount."No." := TestCodeTok;
        BankAccount.Name := 'Fleetrock Test Bank';
        BankAccount."Bank Acc. Posting Group" := TestCodeTok;
        BankAccount.Insert();

        PaymentMethod.Code := TestCodeTok;
        PaymentMethod.Description := 'Fleetrock Test Payment';
        PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"Bank Account";
        PaymentMethod."Bal. Account No." := BankAccount."No.";
        PaymentMethod.Insert();
        PaymentMethodCode := PaymentMethod.Code;

        // Customer and vendor are inserted without triggers so the Fleetrock
        // vendor export is not queued and no number series is needed.
        Customer.Init();
        Customer."No." := TestCodeTok;
        Customer.Name := 'Fleetrock Test Customer';
        Customer."Gen. Bus. Posting Group" := TestCodeTok;
        Customer."VAT Bus. Posting Group" := TestCodeTok;
        Customer."Customer Posting Group" := TestCodeTok;
        Customer."Tax Liable" := false;
        Customer."Tax Area Code" := '';
        Customer.Insert();

        Vendor.Init();
        Vendor."No." := TestCodeTok;
        Vendor.Name := 'Fleetrock Test Vendor';
        Vendor."Gen. Bus. Posting Group" := TestCodeTok;
        Vendor."VAT Bus. Posting Group" := TestCodeTok;
        Vendor."Vendor Posting Group" := TestCodeTok;
        Vendor."Tax Liable" := false;
        Vendor."Tax Area Code" := '';
        Vendor.Insert();

        UnitOfMeasure.Code := TestCodeTok;
        UnitOfMeasure.Description := 'Fleetrock Test';
        UnitOfMeasure.Insert();

        Item.Init();
        Item."No." := TestCodeTok;
        Item.Description := 'Fleetrock Test Item';
        Item.Type := Item.Type::Inventory;
        Item."Base Unit of Measure" := TestCodeTok;
        Item."Sales Unit of Measure" := TestCodeTok;
        Item."Purch. Unit of Measure" := TestCodeTok;
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := TestCodeTok;
        Item."VAT Prod. Posting Group" := TestCodeTok;
        Item."Inventory Posting Group" := TestCodeTok;
        Item."Unit Cost" := 20;
        Item.Insert();
        ItemUnitOfMeasure."Item No." := Item."No.";
        ItemUnitOfMeasure.Code := TestCodeTok;
        ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
        ItemUnitOfMeasure.Insert();

        IsInitialized := true;
    end;

    local procedure CreateNoSeries(Suffix: Text): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Code := CopyStr(TestCodeTok + '-' + Suffix, 1, MaxStrLen(NoSeries.Code));
        NoSeries.Description := NoSeries.Code;
        NoSeries."Default Nos." := true;
        NoSeries.Insert();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", CopyStr(Suffix + 'FRT00001', 1, MaxStrLen(NoSeriesLine."Starting No.")));
        NoSeriesLine.Insert();
        exit(NoSeries.Code);
    end;

    local procedure CreateGLAccount(Suffix: Text): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := CopyStr(TestCodeTok + '-' + Suffix, 1, MaxStrLen(GLAccount."No."));
        GLAccount.Name := CopyStr('Fleetrock Test ' + Suffix, 1, MaxStrLen(GLAccount.Name));
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount."Direct Posting" := true;
        GLAccount."Gen. Prod. Posting Group" := TestCodeTok;
        GLAccount."VAT Prod. Posting Group" := TestCodeTok;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; FleetrockID: Text[20])
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Validate("Location Code", '');
        SalesHeader."EE Fleetrock ID" := FleetrockID;
        SalesHeader.Modify(true);
    end;

    local procedure AddSalesLine(SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
        LineNo: Integer;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No.";

        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine."Line No." := LineNo + 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, LineType);
        SalesLine.Validate("No.", No);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; FleetrockID: Text[20])
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true);
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Validate("Location Code", '');
        if DocumentType = PurchaseHeader."Document Type"::"Credit Memo" then
            PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.")
        else
            PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader."EE Fleetrock ID" := FleetrockID;
        PurchaseHeader.Modify(true);
    end;

    local procedure AddPurchaseLine(PurchaseHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        LineNo: Integer;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindLast() then
            LineNo := PurchaseLine."Line No.";

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine."Line No." := LineNo + 10000;
        PurchaseLine.Insert(true);
        PurchaseLine.Validate(Type, LineType);
        PurchaseLine.Validate("No.", No);
        PurchaseLine.Validate(Quantity, Qty);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Ship := true;
        SalesHeader.Receive := true;
        SalesHeader.Invoice := true;
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
    end;

    local procedure PostSalesInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        PostSalesDocument(SalesHeader);
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure PostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchaseHeader.Receive := true;
        PurchaseHeader.Invoice := true;
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);

        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20]; FleetrockID: Text[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        if GLEntry.IsEmpty() then
            Error('No G/L entries were posted for document %1.', DocumentNo);
        GLEntry.SetFilter("EE Fleetrock ID", '<>%1', FleetrockID);
        if GLEntry.FindFirst() then
            Error('G/L entry %1 (document %2) has Fleetrock ID ''%3'', expected ''%4''.', GLEntry."Entry No.", DocumentNo, GLEntry."EE Fleetrock ID", FleetrockID);
    end;

    // Proves the inventory-to-G/L path ran, so VerifyGLEntries also covered it.
    local procedure VerifyGLAccountPosted(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        if GLEntry.IsEmpty() then
            Error('Expected a G/L entry on %1 for %2; automatic cost posting did not run.', GLAccountNo, DocumentNo);
    end;

    local procedure VerifyPostedDocumentGLEntries(HeaderTableNo: Integer; NoFieldNo: Integer; PostingDateFieldNo: Integer; FleetrockIDFieldNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        HeaderRef: RecordRef;
        FleetrockID: Text[20];
    begin
        HeaderRef.Open(HeaderTableNo);
        HeaderRef.Field(FleetrockIDFieldNo).SetFilter('<>%1', '');
        if not HeaderRef.FindSet() then
            exit;
        repeat
            FleetrockID := HeaderRef.Field(FleetrockIDFieldNo).Value();
            GLEntry.SetRange("Document No.", Format(HeaderRef.Field(NoFieldNo).Value()));
            GLEntry.SetRange("Posting Date", HeaderRef.Field(PostingDateFieldNo).Value());
            GLEntry.SetFilter("EE Fleetrock ID", '<>%1', FleetrockID);
            if GLEntry.FindFirst() then
                Error('G/L entry %1 (document %2) has Fleetrock ID ''%3'', expected ''%4''.', GLEntry."Entry No.", GLEntry."Document No.", GLEntry."EE Fleetrock ID", FleetrockID);
        until HeaderRef.Next() = 0;
    end;
}
