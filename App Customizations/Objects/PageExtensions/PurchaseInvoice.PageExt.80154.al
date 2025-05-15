pageextension 80154 "EEC Purchase Invoice" extends "Purchase Invoice"
{
    layout
    {
        modify("Vendor Invoice No.")
        {
            ShowMandatory = VendorInvoiceNoMandatory;
        }
        modify("Payment Terms Code")
        {
            trigger OnBeforeValidate()
            begin
                Rec."EEC Updated Payment Terms" := true;
            end;
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