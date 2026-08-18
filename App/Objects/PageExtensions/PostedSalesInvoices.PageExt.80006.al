pageextension 80006 "EE Posted Sales Invoices" extends "Posted Sales Invoices"
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
                    SalesHeaderStaging: Record "EE Sales Header Staging";
                begin
                    SalesHeaderStaging.DrillDown(Rec."EE Fleetrock ID");
                end;
            }
            field("Pre-Assigned No."; Rec."Pre-Assigned No.")
            {
                ApplicationArea = All;
            }
        }
    }
}