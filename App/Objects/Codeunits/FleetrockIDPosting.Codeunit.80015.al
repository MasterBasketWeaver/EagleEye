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

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", OnAfterCopyGLEntryFromGenJnlLine, '', false, false)]
    local procedure GLEntryOnAfterCopyFromGenJnlLine(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."EE Fleetrock ID" := GenJournalLine."EE Fleetrock ID";
    end;

    // Inventory cost is posted to G/L from value entries, not from the document,
    // so the ID comes from the posted header, which Sales-Post/Purch.-Post insert
    // before any line is posted. When "Post Inventory Cost to G/L" runs per
    // posting group, the journal line has the batch's own document no. and
    // summarises many value entries, so it is left blank.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Posting To G/L", OnPostInvtPostBufOnAfterInitGenJnlLine, '', false, false)]
    local procedure InvtPostingToGLOnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry")
    begin
        if GenJournalLine."Document No." = ValueEntry."Document No." then
            GenJournalLine."EE Fleetrock ID" := GetPostedDocumentFleetrockID(ValueEntry."Document Type", ValueEntry."Document No.");
    end;

    local procedure GetPostedDocumentFleetrockID(DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]): Text[20]
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        case DocumentType of
            DocumentType::"Sales Invoice":
                begin
                    SalesInvHeader.SetLoadFields("EE Fleetrock ID");
                    if SalesInvHeader.Get(DocumentNo) then
                        exit(SalesInvHeader."EE Fleetrock ID");
                end;
            DocumentType::"Sales Credit Memo":
                begin
                    SalesCrMemoHeader.SetLoadFields("EE Fleetrock ID");
                    if SalesCrMemoHeader.Get(DocumentNo) then
                        exit(SalesCrMemoHeader."EE Fleetrock ID");
                end;
            DocumentType::"Purchase Invoice":
                begin
                    PurchInvHeader.SetLoadFields("EE Fleetrock ID");
                    if PurchInvHeader.Get(DocumentNo) then
                        exit(PurchInvHeader."EE Fleetrock ID");
                end;
            DocumentType::"Purchase Credit Memo":
                begin
                    PurchCrMemoHdr.SetLoadFields("EE Fleetrock ID");
                    if PurchCrMemoHdr.Get(DocumentNo) then
                        exit(PurchCrMemoHdr."EE Fleetrock ID");
                end;
        end;
    end;
}
