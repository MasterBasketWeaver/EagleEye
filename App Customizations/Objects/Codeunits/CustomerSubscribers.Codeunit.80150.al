codeunit 80150 "EEC Custom Subscribers"
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
        IsHandled := Vendor."EEC NonMandatory Ext. Doc. No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeCheckExternalDocumentNumber, '', false, false)]
    local procedure PurchPostOnBeforeCheckExternalDocumentNumber(var Handled: Boolean; PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Handled := Vendor."EEC NonMandatory Ext. Doc. No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeCheckPurchExtDocNoProcedure, '', false, false)]
    local procedure GenJnlPostLineOnBeforeCheckPurchExtDocNoProcedure(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    var
        Vendor: Record Vendor;
    begin
        if GenJnlLine."Source Type" = GenJnlLine."Source Type"::Vendor then
            if Vendor.Get(GenJnlLine."Source No.") then
                IsHandled := Vendor."EEC NonMandatory Ext. Doc. No.";
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
        if PurchPayableSetup.Get() and (PurchPayableSetup."EEC ACH Payment Method" <> '') then begin
            Vendor.Validate("Payment Method Code", PurchPayableSetup."EEC ACH Payment Method");
            Vendor.Modify(true);
        end;
    end;



    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterInsertEvent, '', false, false)]
    local procedure SalesInvoiceHeaderOnAfterInsertEvent(var Rec: Record "Sales Header")
    begin
        CheckToSetDefaultPaymentTerms(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterModifyEvent, '', false, false)]
    local procedure SalesInvoiceHeaderOnAfterModifyEvent(var Rec: Record "Sales Header")
    begin
        CheckToSetDefaultPaymentTerms(Rec);
    end;

    local procedure CheckToSetDefaultPaymentTerms(var SalesHeader: Record "Sales Header")
    var
        SalesRecSetup: Record "Sales & Receivables Setup";
    begin
        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice) or (SalesHeader."EE Fleetrock ID" <> '') or SalesHeader."EEC Updated Payment Terms" then
            exit;
        if not SalesRecSetup.Get() or (SalesRecSetup."EEC Default Payment Terms" = '') then
            exit;
        if SalesHeader."Payment Terms Code" <> SalesRecSetup."EEC Default Payment Terms" then begin
            SalesHeader.Validate("Payment Terms Code", SalesRecSetup."EEC Default Payment Terms");
            SalesHeader.Modify(false);
        end;
    end;


    [EventSubscriber(ObjectType::Table, Database::Customer, OnAfterInsertEvent, '', false, false)]
    local procedure CustomerOnAfterInsert(var Rec: Record Customer)
    var
        SalesRecSetup: Record "Sales & Receivables Setup";
    begin
        SalesRecSetup.Get();
        if Rec."Customer Posting Group" = '' then
            if SalesRecSetup."EEC Default Cust. Post. Group" <> '' then
                Rec.Validate("Customer Posting Group", SalesRecSetup."EEC Default Cust. Post. Group");
        if Rec."Tax Area Code" = '' then
            if SalesRecSetup."EEC Default Tax Area Code" <> '' then begin
                Rec.Validate("Tax Area Code", SalesRecSetup."EEC Default Tax Area Code");
                Rec.Validate("Tax Liable", true);
            end;
    end;
}