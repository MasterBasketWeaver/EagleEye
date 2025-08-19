pageextension 80002 "EE Purchase Order" extends "Purchase Order"
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