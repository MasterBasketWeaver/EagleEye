pageextension 80003 "EE Purchase Order List" extends "Purchase Order List"
{
    layout
    {
        addafter("No.")
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