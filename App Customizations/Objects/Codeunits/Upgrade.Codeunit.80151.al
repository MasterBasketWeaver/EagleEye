codeunit 80151 "EEC Upgrade"
{
    Subtype = Upgrade;

    Permissions = tabledata "Posted Gen. Journal Line" = RD,
    tabledata Vendor = RIMD,
    tabledata "Purchases & Payables Setup" = RIMD,
    tabledata "Cancelled Document" = RIMD,
    tabledata "G/L Entry" = RIMD,
    tabledata "Value Entry" = RIMD,
    tabledata "Item Ledger Entry" = RIMD,
    tabledata "Vendor Ledger Entry" = RIMD,
    tabledata "Detailed Vendor Ledg. Entry" = RIMD,
    tabledata "Purch. Rcpt. Header" = RIMD,
    tabledata "Purch. Rcpt. Line" = RIMD,
    tabledata "Purch. Comment Line" = RIMD,
    tabledata "Purch. Inv. Header" = RIMD,
    tabledata "Purch. Inv. Line" = RIMD;



    trigger OnUpgradePerCompany()
    begin
        InstallData();
    end;

    procedure InstallData()
    begin
        // SetVendorPaymentTerms();
        // CancelInvalidInvoices();
        // RefreshPostingNumbers();
        // RemoveInvalidEntries();
    end;


    local procedure RemoveInvalidEntries()
    var
        GLEntry: Record "G/L Entry";
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DtldVendorLedgerEntry: Record "Detailed Vendor Ledg. Entry";
        VATEntry: Record "VAT Entry";
        CancelledDocument: Record "Cancelled Document";
    begin
        if CompanyName() <> 'Test - Diesel Repair Shop' then
            exit;
        GLEntry.SetFilter("Transaction No.", '%1..%2|%3..%4', 257, 260, 267, 270);
        GLEntry.DeleteAll(false);
        VATEntry.SetFilter("Transaction No.", '%1..%2|%3..%4', 257, 260, 267, 270);
        VATEntry.DeleteAll(false);
        ValueEntry.SetFilter("Entry No.", '%1..%2|%3..%4', 443, 445, 453, 455);
        ValueEntry.DeleteAll(false);
        ItemLedgerEntry.SetFilter("Entry No.", '%1..%2|%3..%4', 441, 443, 451, 453);
        ItemLedgerEntry.DeleteAll(false);
        VendorLedgerEntry.SetFilter("Transaction No.", '%1|%2', 268, 270);
        if VendorLedgerEntry.FindSet(true) then
            repeat
                DtldVendorLedgerEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
                DtldVendorLedgerEntry.DeleteAll(false);
            until VendorLedgerEntry.Next() = 0;
        VendorLedgerEntry.DeleteAll(false);

        DeletePurchRcptTables('107059');
        DeletePurchRcptTables('107061');
        DeletePurchInvTables('PPINV000069');
        DeletePurchInvTables('PPINV000071');
        DeletePurchCrMemoTables('PPCM0000004');
        DeletePurchCrMemoTables('PPCM0000006');

        if CancelledDocument.Get(Database::"Cancelled Document", 'PPINV000069') then
            CancelledDocument.Delete(false);
        if CancelledDocument.Get(Database::"Cancelled Document", 'PPINV000071') then
            CancelledDocument.Delete(false);
    end;

    local procedure DeletePurchRcptTables(DocNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        if not PurchRcptHeader.Get(DocNo) then
            exit;
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.DeleteAll(true);
        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::Receipt);
        PurchCommentLine.SetRange("No.", PurchRcptHeader."No.");
        PurchCommentLine.DeleteAll();
        PurchRcptHeader.Delete(false);
    end;

    local procedure DeletePurchInvTables(DocNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        if not PurchInvHeader.Get(DocNo) then
            exit;
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.DeleteAll(true);
        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::"Posted Invoice");
        PurchCommentLine.SetRange("No.", PurchInvHeader."No.");
        PurchCommentLine.DeleteAll();
        PurchInvHeader.Delete(false);
    end;


    local procedure DeletePurchCrMemoTables(DocNo: Code[20])
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        if not PurchCrMemoHeader.Get(DocNo) then
            exit;
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHeader."No.");
        PurchCrMemoLine.DeleteAll(true);
        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::"Posted Credit Memo");
        PurchCommentLine.SetRange("No.", PurchCrMemoHeader."No.");
        PurchCommentLine.DeleteAll();
        PurchCrMemoHeader.Delete(false);
    end;




    local procedure RefreshPostingNumbers()
    var
        PurchHeader: Record "Purchase Header";
    begin
        if CompanyName() <> 'Test - Diesel Repair Shop' then
            exit;
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetFilter("No.", '%1|%2', '106499', '106501');
        if PurchHeader.FindSet(true) then
            repeat
                PurchHeader."Posting No." := '';
                PurchHeader."Receiving No." := '';
                PurchHeader."EE Fleetrock ID" := '';
                PurchHeader.Modify(false);
            until PurchHeader.Next() = 0;
    end;

    local procedure CancelInvalidInvoices()
    var
        //Cancelled Doc. No.
        CancelledDocument: Record "Cancelled Document";
    begin
        if CompanyName() <> 'Test - Diesel Repair Shop' then
            exit;
        if not CancelledDocument.Get(Database::"Purch. Inv. Header", 'PPINV000069') then
            CancelledDocument.InsertPurchInvToCrMemoCancelledDocument('PPINV000069', 'PPCM0000004');
        if not CancelledDocument.Get(Database::"Purch. Inv. Header", 'PPINV000071') then
            CancelledDocument.InsertPurchInvToCrMemoCancelledDocument('PPINV000071', 'PPCM0000006');
    end;

    local procedure SetVendorPaymentTerms()
    var
        Vendor: Record Vendor;
        PurchPaySetup: Record "Purchases & Payables Setup";
    begin
        Vendor.SetRange("EEC Updated Payment Terms", true);
        if not Vendor.IsEmpty() then
            exit;
        Vendor.SetFilter("Payment Terms Code", '<>%1', '');
        Vendor.SetRange("EEC Updated Payment Terms");
        if PurchPaySetup.Get() and (PurchPaySetup."EEC Default Payment Terms" <> '') then
            Vendor.SetFilter("Payment Terms Code", '<>%1', PurchPaySetup."EEC Default Payment Terms");
        Vendor.ModifyAll("EEC Updated Payment Terms", true);
    end;
}