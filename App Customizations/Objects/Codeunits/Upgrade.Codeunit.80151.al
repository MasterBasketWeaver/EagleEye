codeunit 80151 "EEC Upgrade"
{
    Subtype = Upgrade;

    Permissions = tabledata "Posted Gen. Journal Line" = RD,
    tabledata Vendor = RIMD,
    tabledata "Purchases & Payables Setup" = RIMD,
    tabledata "Cancelled Document" = RIMD;



    trigger OnUpgradePerCompany()
    begin
        InstallData();
    end;

    procedure InstallData()
    begin
        // SetVendorPaymentTerms();
        // CancelInvalidInvoices();
        // RefreshPostingNumbers();
    end;


    local procedure RefreshPostingNumbers()
    var
        PurchHeader: Record "Purchase Header";
    begin
        if CompanyName() <> 'Test - Diesel Repair Shop' then
            exit;
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetFilter("No.", '%1|%2', '106499', '106501');
        if PurchHeader.FindSet(true) then
            repeat
                PurchHeader."Posting No." := '';
                PurchHeader."Receiving No." := '';
                PurchHeader."EE Fleetrock ID" := '';
                PurchHeader.Modify(false);
            until PurchHeader.Next() = 0;
    end;

    local procedure CancelInvalidInvoices()
    var
        //Cancelled Doc. No.
        CancelledDocument: Record "Cancelled Document";
    begin
        if CompanyName() <> 'Test - Diesel Repair Shop' then
            exit;
        if not CancelledDocument.Get(Database::"Purch. Inv. Header", 'PPINV000069') then
            CancelledDocument.InsertPurchInvToCrMemoCancelledDocument('PPINV000069', 'PPCM0000004');
        if not CancelledDocument.Get(Database::"Purch. Inv. Header", 'PPINV000071') then
            CancelledDocument.InsertPurchInvToCrMemoCancelledDocument('PPINV000071', 'PPCM0000006');
    end;

    local procedure SetVendorPaymentTerms()
    var
        Vendor: Record Vendor;
        PurchPaySetup: Record "Purchases & Payables Setup";
    begin
        Vendor.SetRange("EEC Updated Payment Terms", true);
        if not Vendor.IsEmpty() then
            exit;
        Vendor.SetFilter("Payment Terms Code", '<>%1', '');
        Vendor.SetRange("EEC Updated Payment Terms");
        if PurchPaySetup.Get() and (PurchPaySetup."EEC Default Payment Terms" <> '') then
            Vendor.SetFilter("Payment Terms Code", '<>%1', PurchPaySetup."EEC Default Payment Terms");
        Vendor.ModifyAll("EEC Updated Payment Terms", true);
    end;
}