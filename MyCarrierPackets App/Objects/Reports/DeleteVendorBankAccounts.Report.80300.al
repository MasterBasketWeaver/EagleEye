report 80300 "EEMCP Delete V. Bank Accounts"
{
    Caption = 'Delete Vendor Bank Accounts';
    ApplicationArea = All;
    UsageCategory = Tasks;
    ProcessingOnly = true;
    UseRequestPage = false;
    Permissions = tabledata Vendor = RIMD,
    tabledata "Vendor Bank Account" = RIMD,
    tabledata "Vendor Ledger Entry" = R;

    trigger OnPreReport()
    begin
        if not Confirm('Delete all non-ACH vendor bank accounts?', false) then
            CurrReport.Quit();
    end;

    trigger OnPostReport()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        Window: Dialog;
        i, RecCount : Integer;
    begin
        VendorBankAccount.SetFilter(Code, '<>%1', 'ACH');
        RecCount := VendorBankAccount.Count();
        if VendorBankAccount.FindSet() then begin
            Window.Open('Deleting\#1##');
            repeat
                i := i + 1;
                Window.Update(1, StrSubstNo('%1 of %2', i, RecCount));
                VendorBankAccount.Delete(true);
            until VendorBankAccount.Next() = 0;
            Window.Close();
        end;
        Message('Deleted %1 vendor bank accounts.', RecCount);
    end;
}