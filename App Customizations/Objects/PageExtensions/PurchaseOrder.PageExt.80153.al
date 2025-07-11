pageextension 80153 "EEC Purchase Order" extends "Purchase Order"
{
    layout
    {
        modify("Vendor Invoice No.")
        {
            ShowMandatory = VendorInvoiceNoMandatory;
        }
    }

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(Rec."Buy-from Vendor No.") then begin
            PurchPaySetup.GetRecordOnce();
            VendorInvoiceNoMandatory := PurchPaySetup."Ext. Doc. No. Mandatory";
        end else
            VendorInvoiceNoMandatory := not Vendor."EEC NonMandatory Ext. Doc. No.";
    end;

    var
        PurchPaySetup: Record "Purchases & Payables Setup";
        VendorInvoiceNoMandatory: Boolean;
}