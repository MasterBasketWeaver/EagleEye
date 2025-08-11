pageextension 80007 "EE Posted Purchase Invoice" extends "Posted Purchase Invoice"
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