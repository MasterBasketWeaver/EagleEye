pageextension 80017 "EE Posted Purch. Cr.Memo" extends "Posted Purchase Credit Memo"
{
    layout
    {
        addlast(General)
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