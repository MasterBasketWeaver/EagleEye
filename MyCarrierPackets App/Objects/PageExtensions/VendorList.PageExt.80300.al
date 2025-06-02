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
                    Install: Codeunit "EEMCP Install";
                begin
                    Install.InstallData();
                    Message('done');
                end;
            }
        }
    }
}