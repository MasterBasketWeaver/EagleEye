pageextension 80300 "EEMCP Vendors" extends "Vendor List"
{
    layout
    {
        addlast(Control1)
        {
            field("EEMCP Dot No."; Rec."EEMCP Dot No.")
            {
                ApplicationArea = all;
            }
            field("EEMCP Docket No."; Rec."EEMCP Docket No.")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("EEMCP Delete all")
            {
                ApplicationArea = all;
                Image = Delete;
                Caption = 'Delete All';

                trigger OnAction()
                var
                    Window: Dialog;
                    i, RecCount : Integer;
                begin
                    if not Confirm('Delete all?') then
                        exit;
                    RecCount := Rec.Count();
                    Window.Open('Deleting\#1##');
                    if Rec.FindSet(true) then
                        repeat
                            i += 1;
                            Window.Update(1, StrSubstNo('%1 of %2', i, RecCount));
                            Rec.Delete(true);
                        until Rec.Next() = 0;
                    Window.Close();
                end;
            }
            action("EEMCP Delete Blank Bank Accounts")
            {
                ApplicationArea = all;
                Image = Delete;
                Caption = 'Delete Blank Bank Accounts';

                trigger OnAction()
                var

                    VendorBankAccount: Record "Vendor Bank Account";
                    i: Integer;
                begin
                    if not Confirm('Delete all blank vendor bank accounts?') then
                        exit;
                    VendorBankAccount.SetRange(Code, '');
                    i := VendorBankAccount.Count();
                    Install.ClearVendorBankAccounts();
                    Message('done: %1 -> %2', i, VendorBankAccount.Count());
                end;
            }
            action("EEMCP Set Default Bank Account")
            {
                ApplicationArea = all;
                Image = Bank;
                Caption = 'Set Default Bank Account';

                trigger OnAction()
                var
                    RecRef: RecordRef;
                    i: Integer;
                begin
                    RecRef.Open(Database::Vendor);
                    RecRef.Field(Rec.FieldNo("Preferred Bank Account Code")).SetRange('');
                    if RecRef.FieldExist(60700) then
                        RecRef.Field(60700).SetRange(true);
                    i := RecRef.Count();
                    Install.PopulateVendorBankAccounts();
                    Message('done: %1 -> %2', i, RecRef.Count());
                end;
            }
            action("EEMCP Set Document Layouts")
            {
                ApplicationArea = all;
                Image = Bank;
                Caption = 'Set Document Layouts';

                trigger OnAction()
                var
                    PurchPaySetup: Record "Purchases & Payables Setup";
                    MCPMgt: Codeunit "EEMCP My Carrier Packets Mgt.";
                begin
                    PurchPaySetup.Get();
                    PurchPaySetup.TestField("EEC ACH Payment Method");
                    Message('Updated: %1', MCPMgt.SetVendorDocumentLayouts(PurchPaySetup."EEC ACH Payment Method"));
                end;
            }
        }
    }

    var
        Install: Codeunit "EEMCP Install";
}