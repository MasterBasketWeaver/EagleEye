pageextension 80154 "EE Purchase Invoice" extends "Purchase Invoice"
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
            VendorInvoiceNoMandatory := not Vendor."EE Non-Mandatory Ext. Doc. No.";
    end;

    var
        PurchPaySetup: Record "Purchases & Payables Setup";
        VendorInvoiceNoMandatory: Boolean;
}