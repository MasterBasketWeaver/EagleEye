codeunit 80151 "EEC Upgrade"
{
    Subtype = Upgrade;

    Permissions = tabledata "Posted Gen. Journal Line" = RD,
    tabledata Vendor = RIMD,
    tabledata "Purchases & Payables Setup" = RIMD;

    trigger OnUpgradePerCompany()
    begin
        InstallData();
    end;

    procedure InstallData()
    begin
        SetVendorPaymentTerms();
    end;

    local procedure SetVendorPaymentTerms()
    var
        Vendor: Record Vendor;
        PurchPaySetup: Record "Purchases & Payables Setup";
    begin
        Vendor.SetRange("EEC Updated Payment Terms", true);
        if not Vendor.IsEmpty() then
            exit;
        Vendor.SetRange("EEC Updated Payment Terms");
        if PurchPaySetup.Get() and (PurchPaySetup."EEC Default Payment Terms" <> '') then
            Vendor.SetFilter("Payment Terms Code", '<>%1', PurchPaySetup."EEC Default Payment Terms");
        Vendor.ModifyAll("EEC Updated Payment Terms", true);
    end;
}