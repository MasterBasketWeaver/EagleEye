pageextension 80011 "EE Sales Invoice" extends "Sales Invoice"
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
                    SalesHeaderStaging: Record "EE Sales Header Staging";
                begin
                    SalesHeaderStaging.DrillDown(Rec."EE Fleetrock ID");
                end;
            }
        }
    }
}