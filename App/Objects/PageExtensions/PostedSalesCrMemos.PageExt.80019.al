pageextension 80019 "EE Posted Sales Credit Memos" extends "Posted Sales Credit Memos"
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