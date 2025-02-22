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
}