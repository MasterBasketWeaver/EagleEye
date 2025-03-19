pageextension 80005 "EE Posted Sales Invoice" extends "Posted Sales Invoice"
{
    layout
    {
        addlast(General)
        {
            field("EE Fleetrock ID"; Rec."EE Fleetrock ID")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("EE Send Payment")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = PaymentJournal;
                Caption = 'Send Payment';
                ToolTip = 'Updated the related Fleetrock invoice as paid.';
                Enabled = Rec."EE Fleetrock ID" <> '';

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                begin
                    Rec.TestField("EE Fleetrock ID");
                    if Rec."EE Sent Payment" then
                        Error('Invoice %1 already sent payment at %2', Rec."No.", Rec."EE Sent Payment DateTime");
                    Rec.CalcFields(Closed, "Remaining Amount");
                    if not Rec.Closed or (Rec."Remaining Amount" > 0) then
                        Error('Invoice %1 is not fully paid.', Rec."No.");
                    FleetrockMgt.UpdatePaidRepairOrder(Rec."EE Fleetrock ID", CurrentDateTime(), Rec);
                    Rec.Get(Rec."No.");
                    if Rec."EE Sent Payment" then
                        Message('Payment sent successfully.')
                    else
                        Error('Failed to send payment.');
                end;
            }
        }
    }
}