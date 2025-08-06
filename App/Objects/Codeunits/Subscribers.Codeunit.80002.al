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





    var
        SingleInstance: Codeunit "EE Single Instance";
}