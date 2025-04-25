codeunit 80150 "EE Custom Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "No.", false, false)]
    local procedure PurchaseLineOnAfterValidateNo(var Rec: Record "Purchase Line")
    begin
        if Rec."Description 2" = '' then
            Rec."Description 2" := CopyStr(Rec.Description, 1, MaxStrLen(Rec."Description 2"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnAfterValidateEvent, "No.", false, false)]
    local procedure SalesLineOnAfterValidateNo(var Rec: Record "Sales Line")
    begin
        if Rec."Description 2" = '' then
            Rec."Description 2" := CopyStr(Rec.Description, 1, MaxStrLen(Rec."Description 2"));
    end;




    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeCheckExtDocNo, '', false, false)]
    local procedure PurchPostOnBeforeCheckExtDocNo(var IsHandled: Boolean; PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        IsHandled := Vendor."EE Non-Mandatory Ext. Doc. No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeCheckExternalDocumentNumber, '', false, false)]
    local procedure PurchPostOnBeforeCheckExternalDocumentNumber(var Handled: Boolean; PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Handled := Vendor."EE Non-Mandatory Ext. Doc. No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeCheckPurchExtDocNoProcedure, '', false, false)]
    local procedure GenJnlPostLineOnBeforeCheckPurchExtDocNoProcedure(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    var
        Vendor: Record Vendor;
    begin
        if GenJnlLine."Source Type" = GenJnlLine."Source Type"::Vendor then
            if Vendor.Get(GenJnlLine."Source No.") then
                IsHandled := Vendor."EE Non-Mandatory Ext. Doc. No.";
    end;




    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", OnAfterInsertEvent, '', false, false)]
    local procedure VendorBankAccountOnAfterInsert(var Rec: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Vendor No.") then
            UpdateVendorDefaultPaymentMethod(Vendor);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", OnAfterModifyEvent, '', false, false)]
    local procedure VendorBankAccountOnAfterModifyEvent(var Rec: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Vendor No.") then
            UpdateVendorDefaultPaymentMethod(Vendor);
    end;

    local procedure UpdateVendorDefaultPaymentMethod(var Vendor: Record Vendor)
    var
        PurchPayableSetup: Record "Purchases & Payables Setup";
    begin
        if PurchPayableSetup.Get() and (PurchPayableSetup."EE ACH Payment Method" <> '') then begin
            Vendor.Validate("Payment Method Code", PurchPayableSetup."EE ACH Payment Method");
            Vendor.Modify(true);
        end;
    end;



    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Header", OnAfterInsertEvent, '', false, false)]
    local procedure SalesInvoiceHeaderOnAfterInsertEvent(var Rec: Record "Sales Invoice Header")
    var
        SalesRecSetup: Record "Sales & Receivables Setup";
    begin
        if Rec."EE Fleetrock ID" = '' then
            SetDefaultPaymentTerms(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Header", OnAfterModifyEvent, '', false, false)]
    local procedure SalesInvoiceHeaderOnAfterModifyEvent(var Rec: Record "Sales Invoice Header")
    var
        SalesRecSetup: Record "Sales & Receivables Setup";
    begin
        if Rec."EE Fleetrock ID" = '' then
            SetDefaultPaymentTerms(Rec);
    end;

    local procedure SetDefaultPaymentTerms(var SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesRecSetup: Record "Sales & Receivables Setup";
    begin
        if not SalesRecSetup.Get() or (SalesRecSetup."EE Default Payment Terms" = '') then
            exit;
        if SalesInvHeader."Payment Terms Code" <> SalesRecSetup."EE Default Payment Terms" then
            SalesInvHeader.Validate("Payment Terms Code", SalesRecSetup."EE Default Payment Terms");
    end;
}