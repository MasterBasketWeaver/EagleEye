codeunit 80002 "EE Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterValidateEvent, "Buy-from Vendor No.", false, false)]
    local procedure PurchaseHeaderOnAfterValidateButFromVendorNo(var Rec: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Buy-from Vendor No.") then
            if Vendor."Tax Area Code" <> '' then
                Rec.Validate("Tax Area Code", Vendor."Tax Area Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeInsertInvoiceHeader, '', false, false)]
    local procedure SalesPostOnBeforeInsertInvoiceHeader(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header")
    var
        Vendor: Record Vendor;
    begin
        SalesInvHeader."Order No." := SalesHeader."No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, OnAfterInsertEvent, '', false, false)]
    local procedure VendorOnAfterInsertEvent(var Rec: Record Vendor; RunTrigger: Boolean)
    begin
        if RunTrigger then
            CheckToExportVendorDetails(Rec, Rec."EE Export Event Type"::Created);
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, OnAfterModifyEvent, '', false, false)]
    local procedure VendorOnAfterModifyEvent(var Rec: Record Vendor; RunTrigger: Boolean)
    begin
        if RunTrigger then
            CheckToExportVendorDetails(Rec, Rec."EE Export Event Type"::Updated);
    end;

    local procedure CheckToExportVendorDetails(var Vendor: Record Vendor; EventType: Enum "EE Event Type")
    begin
        if not SingleInstance.GetSkipVendorUpdate() and
                ((Vendor."EE Export Event Type" = Vendor."EE Export Event Type"::" ") or (Vendor."EE Export Event Type".AsInteger() = 0)) then begin
            Vendor."EE Export Event Type" := EventType;
            Vendor.Modify(false);
        end;
    end;





    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", OnAfterCreateCorrectivePurchCrMemo, '', false, false)]
    local procedure CorrectPostedPurchInvoiceOnAfterCreateCorrectivePurchCrMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        TaxAreaCode: Code[20];
    begin
        if PurchaseHeader."Tax Area Code" <> '' then
            exit;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.SetFilter("Tax Area Code", '<>%1', '');
        if not PurchaseLine.FindFirst() then
            exit;
        TaxAreaCode := PurchaseLine."Tax Area Code";
        PurchaseLine.SetFilter("Line No.", '<>%1', PurchaseLine."Line No.");
        PurchaseLine.SetFilter("Tax Area Code", '<>%1', TaxAreaCode);
        if not PurchaseLine.IsEmpty() then
            exit;
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
    end;




    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", OnBeforeErrorIfPositiveAmt, '', false, false)]
    local procedure GenJnlCheckLineOnBeforeErrorIfPositiveAmt(var RaiseError: Boolean)
    begin
        if SingleInstance.GetAllowNegativePurchAmount() then
            RaiseError := false;
    end;



    // OnAfterPostApply
    // [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", OnMoveGenJournalBatch, '', false, false)]
    // local procedure GenJournalBatchOnMoveGenJournalBatch(ToRecordID: RecordId)
    // var
    //     RecRef: RecordRef;
    // begin
    //     if RecRef.Get(ToRecordID) then
    //         if RecRef.Number() = Database::"G/L Register" then
    //             FleetrockMgt.CheckForPaidCustLedgerEntries(RecRef);
    // end;





    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnBeforeProcessLines, '', false, false)]
    local procedure GenJnlPostBatchOnBeforeProcessLines()
    begin
        SingleInstance.ClearAppliedSalesInvHeaderNos();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterPostApply, '', false, false)]
    local procedure GenJnlPostLineOnAfterPostApply(GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if OldCVLedgEntryBuf."Document Type" = OldCVLedgEntryBuf."Document Type"::Invoice then
            if SalesInvHeader.Get(OldCVLedgEntryBuf."Document No.") then
                if SalesInvHeader."EE Fleetrock ID" <> '' then
                    SingleInstance.AddAppliedSalesInvHeaderNo(SalesInvHeader."No.", NewCVLedgEntryBuf."Posting Date");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnAfterProcessLines, '', false, false)]
    local procedure GenJnlPostBatchOnAfterProcessLines(SuppressCommit: Boolean; PreviewMode: Boolean)
    var
        DocNoList: Dictionary of [Code[20], Date];
    begin
        if not SuppressCommit and not PreviewMode then begin
            DocNoList := SingleInstance.GetAppliedSalesInvHeaderNos();
            if DocNoList.Count() > 0 then
                FleetrockMgt.UpdatePaidRepairOrders(DocNoList);
        end;
        SingleInstance.ClearAppliedSalesInvHeaderNos();
    end;




    var
        FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
        SingleInstance: Codeunit "EE Single Instance";
}