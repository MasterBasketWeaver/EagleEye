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
            UpdateVendorACHPaymentMethod(Vendor);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", OnAfterModifyEvent, '', false, false)]
    local procedure VendorBankAccountOnAfterModifyEvent(var Rec: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Vendor No.") then
            UpdateVendorACHPaymentMethod(Vendor);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", OnAfterDeleteEvent, '', false, false)]
    local procedure VendorBankAccountOnAfterDeleteEvent(var Rec: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Vendor No.") then
            UpdateVendorCheckPaymentMethod(Vendor);
    end;

    local procedure UpdateVendorACHPaymentMethod(var Vendor: Record Vendor)
    var
        PurchPayableSetup: Record "Purchases & Payables Setup";
    begin
        if Vendor."EEC Updated Payment Method" then
            exit;
        if PurchPayableSetup.Get() and (PurchPayableSetup."EEC ACH Payment Method" <> '') and (Vendor."Payment Method Code" <> PurchPayableSetup."EEC ACH Payment Method") then begin
            Vendor.Validate("Payment Method Code", PurchPayableSetup."EEC ACH Payment Method");
            Vendor.Modify(false);
        end;
    end;

    local procedure UpdateVendorCheckPaymentMethod(var Vendor: Record Vendor)
    var
        PurchPayableSetup: Record "Purchases & Payables Setup";
    begin
        if Vendor."EEC Updated Payment Method" then
            exit;
        if PurchPayableSetup.Get() and (PurchPayableSetup."EEC Check Payment Method" <> '') and (Vendor."Payment Method Code" <> PurchPayableSetup."EEC Check Payment Method") then begin
            Vendor.Validate("Payment Method Code", PurchPayableSetup."EEC Check Payment Method");
            Vendor.Modify(false);
        end;
    end;







    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterInsertEvent, '', false, false)]
    local procedure SalesHeaderOnAfterInsertEvent(var Rec: Record "Sales Header")
    begin
        CheckToSetDefaultPaymentTerms(Rec);
        CheckToSetDefaultPaymentMethod(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterModifyEvent, '', false, false)]
    local procedure SalesHeaderOnAfterModifyEvent(var Rec: Record "Sales Header")
    begin
        CheckToSetDefaultPaymentTerms(Rec);
        CheckToSetDefaultPaymentMethod(Rec);
    end;

    local procedure CheckToSetDefaultPaymentTerms(var SalesHeader: Record "Sales Header")
    var
        SalesRecSetup: Record "Sales & Receivables Setup";
    begin
        if SalesHeader.IsTemporary then
            exit;
        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice) or (SalesHeader."EE Fleetrock ID" <> '') or SalesHeader."EEC Updated Payment Terms" then
            exit;
        if not SalesRecSetup.Get() or (SalesRecSetup."EEC Default Payment Terms" = '') then
            exit;
        if SalesHeader."Payment Terms Code" <> SalesRecSetup."EEC Default Payment Terms" then begin
            SalesHeader.Validate("Payment Terms Code", SalesRecSetup."EEC Default Payment Terms");
            SalesHeader.Modify(false);
        end;
    end;

    local procedure CheckToSetDefaultPaymentMethod(var SalesHeader: Record "Sales Header")
    var
        SalesRecSetup: Record "Sales & Receivables Setup";
    begin
        if SalesHeader.IsTemporary then
            exit;
        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice) or (SalesHeader."EE Fleetrock ID" <> '') or SalesHeader."EEC Updated Payment Method" then
            exit;
        if not SalesRecSetup.Get() or (SalesRecSetup."EEC Default Payment Method" = '') then
            exit;
        if SalesHeader."Payment Method Code" <> SalesRecSetup."EEC Default Payment Method" then begin
            SalesHeader.Validate("Payment Method Code", SalesRecSetup."EEC Default Payment Method");
            SalesHeader.Modify(false);
        end;
    end;



    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterInsertEvent, '', false, false)]
    local procedure PurchaseHeaderOnAfterInsertEvent(var Rec: Record "Purchase Header")
    begin
        CheckToSetDefaultPaymentTerms(Rec);
        // CheckToSetDefaultPaymentMethod(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterModifyEvent, '', false, false)]
    local procedure PurchaseHeaderOnAfterModifyEvent(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        PurchPaySetup: Record "Purchases & Payables Setup";
    begin
        if not RunTrigger then
            exit;
        CheckToSetDefaultPaymentTerms(Rec);
        if Rec."Payment Terms Code" = '' then begin
            PurchPaySetup.Get();
            if PurchPaySetup."EEC Default Payment Terms" <> '' then
                Rec.Validate("Payment Terms Code", PurchPaySetup."EEC Default Payment Terms");
        end else
            Rec.Validate("Payment Terms Code");
        Rec.Modify(false);
    end;

    local procedure CheckToSetDefaultPaymentTerms(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        PurchaseRecSetup: Record "Purchases & Payables Setup";
    begin
        if PurchaseHeader.IsTemporary then
            exit;
        if Vendor.Get(PurchaseHeader."Buy-from Vendor No.") then
            if Vendor."EEC Updated Payment Terms" then
                if Vendor."Payment Terms Code" <> '' then
                    exit;
        if (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice) or (PurchaseHeader."EE Fleetrock ID" <> '') or PurchaseHeader."EEC Updated Payment Terms" then
            exit;
        if not PurchaseRecSetup.Get() or (PurchaseRecSetup."EEC Default Payment Terms" = '') then
            exit;
        if PurchaseHeader."Payment Terms Code" <> PurchaseRecSetup."EEC Default Payment Terms" then begin
            PurchaseHeader.Validate("Payment Terms Code", PurchaseRecSetup."EEC Default Payment Terms");
            PurchaseHeader.Modify(false);
        end;
    end;

    local procedure CheckToSetDefaultPaymentMethod(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        PurchaseRecSetup: Record "Purchases & Payables Setup";
    begin
        if PurchaseHeader.IsTemporary then
            exit;
        if Vendor.Get(PurchaseHeader."Buy-from Vendor No.") then
            if Vendor."EEC Updated Payment Method" then
                if Vendor."Payment Method Code" <> '' then
                    exit;
        if (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice) or (PurchaseHeader."EE Fleetrock ID" <> '') or PurchaseHeader."EEC Updated Payment Method" then
            exit;
        if not PurchaseRecSetup.Get() or (PurchaseRecSetup."EEC Default Payment Method" = '') then
            exit;
        if PurchaseHeader."Payment Method Code" <> PurchaseRecSetup."EEC Default Payment Method" then begin
            PurchaseHeader.Validate("Payment Method Code", PurchaseRecSetup."EEC Default Payment Method");
            PurchaseHeader.Modify(false);
        end;
    end;



    [EventSubscriber(ObjectType::Table, Database::Customer, OnAfterInsertEvent, '', false, false)]
    local procedure CustomerOnAfterInsert(var Rec: Record Customer)
    var
        SalesRecSetup: Record "Sales & Receivables Setup";
        Updated: Boolean;
    begin
        if Rec.IsTemporary then
            exit;
        SalesRecSetup.Get();
        if Rec."Customer Posting Group" = '' then
            if SalesRecSetup."EEC Default Cust. Post. Group" <> '' then begin
                Rec.Validate("Customer Posting Group", SalesRecSetup."EEC Default Cust. Post. Group");
                Updated := true;
            end;
        if Rec."Tax Area Code" = '' then
            if SalesRecSetup."EEC Default Tax Area Code" <> '' then begin
                Rec.Validate("Tax Area Code", SalesRecSetup."EEC Default Tax Area Code");
                Rec.Validate("Tax Liable", true);
                Updated := true;
            end;
        if Rec."Payment Terms Code" = '' then
            if SalesRecSetup."EEC Default Payment Terms" <> '' then begin
                Rec.Validate("Payment Terms Code", SalesRecSetup."EEC Default Payment Terms");
                Updated := true;
            end;
        if Rec."Payment Method Code" = '' then
            if SalesRecSetup."EEC Default Payment Method" <> '' then begin
                Rec.Validate("Payment Method Code", SalesRecSetup."EEC Default Payment Method");
                Updated := true;
            end;
        if Updated then
            Rec.Modify(true);
    end;



    [EventSubscriber(ObjectType::Table, Database::Vendor, OnAfterInsertEvent, '', false, false)]
    local procedure VendorOnAfterInsert(var Rec: Record Vendor)
    var
        PurchPaySetup: Record "Purchases & Payables Setup";
        Updated: Boolean;
    begin
        if Rec.IsTemporary then
            exit;
        PurchPaySetup.Get();
        if Rec."Vendor Posting Group" = '' then
            if PurchPaySetup."EEC Default Vend. Post. Group" <> '' then begin
                Rec.Validate("Vendor Posting Group", PurchPaySetup."EEC Default Vend. Post. Group");
                Updated := true;
            end;
        if Rec."Payment Terms Code" <> '' then
            if PurchPaySetup."EEC Default Payment Terms" <> '' then begin
                Rec.Validate("Payment Terms Code", PurchPaySetup."EEC Default Payment Terms");
                Updated := true;
            end;
        if Rec."Payment Method Code" = '' then
            if PurchPaySetup."EEC Default Payment Method" <> '' then begin
                Rec.Validate("Payment Method Code", PurchPaySetup."EEC Default Payment Method");
                Updated := true;
            end;
        if Updated then
            Rec.Modify(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, OnAfterModifyEvent, '', false, false)]
    local procedure VendorOnAfterModify(var Rec: Record Vendor; RunTrigger: Boolean)
    var
        PurchPaySetup: Record "Purchases & Payables Setup";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        if Rec.IsTemporary or not RunTrigger then
            exit;
        VendorBankAccount.SetRange("Vendor No.", Rec."No.");
        if VendorBankAccount.IsEmpty() then
            UpdateVendorCheckPaymentMethod(Rec)
        else
            UpdateVendorACHPaymentMethod(Rec);
    end;




    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", "OnBeforeTestIfInvoiceIsPaid", '', false, false)]
    local procedure CorrectPostedPurchInvoiceOnBeforeTestIfInvoiceIsPaid(var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
        if CompanyName() = 'Test - Diesel Repair Shop' then
            if PurchInvHeader."No." in ['PPINV000069', 'PPINV000071'] then
                IsHandled := true;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", "OnAfterCreateCopyDocument", '', false, false)]
    local procedure CorrectPostedPurchInvoiceOnAfterCreateCopyDocument(var PurchaseHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        if CompanyName() = 'Test - Diesel Repair Shop' then
            if PurchInvHeader."No." in ['PPINV000069', 'PPINV000071'] then
                PurchaseHeader."Tax Area Code" := PurchInvHeader."Tax Area Code";
    end;
}