codeunit 80302 "EEMCP Install"
{
    Subtype = Install;
    Permissions = tabledata "Vendor Bank Account" = RIMD,
    tabledata "Vendor Ledger Entry" = RIMD;

    trigger OnInstallAppPerCompany()
    begin
        InstallData();
    end;

    procedure InstallData()
    begin
        if CompanyName() <> 'Test - CTS' then
            exit;

        // ClearVendorBankAccounts();
        // PopulateVendorBankAccounts();
    end;





    procedure PopulateVendorBankAccounts()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        RecRef: RecordRef;
    begin
        VendorBankAccount.SetLoadFields("Vendor No.", Code, "Use for Electronic Payments");
        VendorBankAccount.SetFilter(Code, '<>%1', '');
        VendorBankAccount.SetRange("Use for Electronic Payments", true);
        RecRef.Open(Database::Vendor);
        RecRef.Field(Vendor.FieldNo("Preferred Bank Account Code")).SetRange('');
        if RecRef.FieldExist(60700) then
            RecRef.Field(60700).SetRange(true);
        if RecRef.FindSet() then
            repeat
                RecRef.SetTable(Vendor);
                VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
                if VendorBankAccount.FindFirst() then begin
                    Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
                    Vendor.Modify(true);
                end;
            until RecRef.Next() = 0;
    end;

    procedure ClearVendorBankAccounts()
    var
        VendorBankAccount, VendorBankAccount2 : Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        NewBankAccountCode: Code[20];
    begin
        VendorBankAccount.SetRange(Code, '');
        if VendorBankAccount.FindSet() then
            repeat
                if Vendor.Get(VendorBankAccount."Vendor No.") then;
                VendorLedgerEntry.SetRange("Vendor No.", VendorBankAccount."Vendor No.");
                VendorLedgerEntry.SetRange("Recipient Bank Account", VendorBankAccount.Code);
                VendorLedgerEntry.SetRange(Open, true);
                if VendorLedgerEntry.FindSet() then begin
                    NewBankAccountCode := '';
                    if (Vendor."Preferred Bank Account Code" <> '') and VendorBankAccount2.Get(Vendor."Preferred Bank Account Code") then
                        NewBankAccountCode := VendorBankAccount2.Code
                    else begin
                        VendorBankAccount2.SetFilter(Code, '<>%1', '');
                        VendorBankAccount2.SetRange("Vendor No.", Vendor."No.");
                        if VendorBankAccount2.FindFirst() then
                            NewBankAccountCode := VendorBankAccount2.Code
                    end;
                    if NewBankAccountCode <> '' then begin
                        repeat
                            VendorLedgerEntry."Recipient Bank Account" := NewBankAccountCode;
                            VendorLedgerEntry.Modify(false);
                        until VendorLedgerEntry.Next() = 0;
                        VendorBankAccount.Delete(true);
                    end;
                end else
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