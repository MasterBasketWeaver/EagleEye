codeunit 80015 "EE Fleetrock ID Posting"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterCopyGenJnlLineFromSalesHeader, '', false, false)]
    local procedure GenJnlLineOnAfterCopyFromSalesHeader(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."EE Fleetrock ID" := SalesHeader."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterCopyGenJnlLineFromSalesHeaderPrepmt, '', false, false)]
    local procedure GenJnlLineOnAfterCopyFromSalesHeaderPrepmt(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."EE Fleetrock ID" := SalesHeader."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost, '', false, false)]
    local procedure GenJnlLineOnAfterCopyFromSalesHeaderPrepmtPost(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."EE Fleetrock ID" := SalesHeader."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterCopyGenJnlLineFromPurchHeader, '', false, false)]
    local procedure GenJnlLineOnAfterCopyFromPurchHeader(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."EE Fleetrock ID" := PurchaseHeader."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterCopyGenJnlLineFromPurchHeaderPrepmt, '', false, false)]
    local procedure GenJnlLineOnAfterCopyFromPurchHeaderPrepmt(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."EE Fleetrock ID" := PurchaseHeader."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterCopyGenJnlLineFromPurchHeaderPrepmtPost, '', false, false)]
    local procedure GenJnlLineOnAfterCopyFromPurchHeaderPrepmtPost(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."EE Fleetrock ID" := PurchaseHeader."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", OnAfterCopyItemJnlLineFromSalesHeader, '', false, false)]
    local procedure ItemJnlLineOnAfterCopyFromSalesHeader(var ItemJnlLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header")
    begin
        ItemJnlLine."EE Fleetrock ID" := SalesHeader."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", OnAfterCopyItemJnlLineFromPurchHeader, '', false, false)]
    local procedure ItemJnlLineOnAfterCopyFromPurchHeader(var ItemJnlLine: Record "Item Journal Line"; PurchHeader: Record "Purchase Header")
    begin
        ItemJnlLine."EE Fleetrock ID" := PurchHeader."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", OnAfterCopyGLEntryFromGenJnlLine, '', false, false)]
    local procedure GLEntryOnAfterCopyFromGenJnlLine(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."EE Fleetrock ID" := GenJournalLine."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnAfterCopyCustLedgerEntryFromGenJnlLine, '', false, false)]
    local procedure CustLedgerEntryOnAfterCopyFromGenJnlLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CustLedgerEntry."EE Fleetrock ID" := GenJournalLine."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterCopyVendLedgerEntryFromGenJnlLine, '', false, false)]
    local procedure VendorLedgerEntryOnAfterCopyFromGenJnlLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VendorLedgerEntry."EE Fleetrock ID" := GenJournalLine."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeInsertDtldCustLedgEntry, '', false, false)]
    local procedure GenJnlPostLineOnBeforeInsertDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        DtldCustLedgEntry."EE Fleetrock ID" := GenJournalLine."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeInsertDtldVendLedgEntry, '', false, false)]
    local procedure GenJnlPostLineOnBeforeInsertDtldVendLedgEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        DtldVendLedgEntry."EE Fleetrock ID" := GenJournalLine."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Entry", OnAfterCopyFromGenJnlLine, '', false, false)]
    local procedure VATEntryOnAfterCopyFromGenJnlLine(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VATEntry."EE Fleetrock ID" := GenJournalLine."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account Ledger Entry", OnAfterCopyFromGenJnlLine, '', false, false)]
    local procedure BankAccLedgerEntryOnAfterCopyFromGenJnlLine(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        BankAccountLedgerEntry."EE Fleetrock ID" := GenJournalLine."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterInitItemLedgEntry, '', false, false)]
    local procedure ItemJnlPostLineOnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        NewItemLedgEntry."EE Fleetrock ID" := ItemJournalLine."EE Fleetrock ID";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterInitValueEntry, '', false, false)]
    local procedure ItemJnlPostLineOnAfterInitValueEntry(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        ValueEntry."EE Fleetrock ID" := ItemJournalLine."EE Fleetrock ID";
    end;

    // When "Post Inventory Cost to G/L" runs per posting group, one journal line
    // summarises many value entries under the batch's own document no., so the
    // value entry passed here is not the line's only source.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Posting To G/L", OnPostInvtPostBufOnAfterInitGenJnlLine, '', false, false)]
    local procedure InvtPostingToGLOnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry")
    begin
        if GenJournalLine."Document No." = ValueEntry."Document No." then
            GenJournalLine."EE Fleetrock ID" := ValueEntry."EE Fleetrock ID";
    end;
}
