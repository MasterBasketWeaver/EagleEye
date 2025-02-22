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
            action("EE Test Update")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = UpdateDescription;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                begin
                    FleetrockMgt.UpdatePaidRepairOrder(Rec."EE Fleetrock ID", CurrentDateTime());
                end;
            }
        }
    }
}