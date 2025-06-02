codeunit 80302 "EEMCP Install"
{
    Subtype = Install;
    Permissions = tabledata "Vendor Bank Account" = RIMD;

    // trigger OnInstallAppPerCompany()
    // begin
    //     InstallData();
    // end;

    procedure InstallData()
    begin
        if CompanyName() <> 'Test - CTS' then
            exit;

        ClearVendorBankAccounts();
    end;

    local procedure ClearVendorBankAccounts()
    var
        VendorBankAccount, VendorBankAccount2 : Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        VendorBankAccount.SetRange(Code, '');
        if VendorBankAccount.FindSet() then
            repeat
                if Vendor.Get(VendorBankAccount."Vendor No.") then;
                VendorLedgerEntry.SetRange("Vendor No.", VendorBankAccount."Vendor No.");
                VendorLedgerEntry.SetRange("Recipient Bank Account", VendorBankAccount.Code);
                VendorLedgerEntry.SetRange(Open, true);
                if VendorLedgerEntry.IsEmpty() then
                    VendorBankAccount.Delete(true);
                if Vendor."No." <> '' then
                    if Vendor."Preferred Bank Account Code" = '' then begin
                        VendorBankAccount2.SetFilter(Code, '<>%1', '');
                        VendorBankAccount2.SetRange("Vendor No.", Vendor."No.");
                        if VendorBankAccount2.FindFirst() then begin
                            Vendor."Preferred Bank Account Code" := VendorBankAccount2.Code;
                            Vendor.Modify(false);
                        end;
                    end;
            until VendorBankAccount.Next() = 0;
    end;
}