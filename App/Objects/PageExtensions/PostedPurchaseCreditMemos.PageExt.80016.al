pageextension 80016 "EE Posted Purch. Cr.Memos" extends "Posted Purchase Credit Memos"
{
    layout
    {
        addlast(Control1)
        {
            field("EE Fleetrock ID"; Rec."EE Fleetrock ID")
            {
                ApplicationArea = all;

                trigger OnDrillDown()
                var
                    PurchHeaderStaging: Record "EE Purch. Header Staging";
                begin
                    PurchHeaderStaging.DrillDown(Rec."EE Fleetrock ID");
                end;
            }
        }
    }
}