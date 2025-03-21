pageextension 80006 "EE Posted Sales Invoices" extends "Posted Sales Invoices"
{
    layout
    {
        addafter("No.")
        {
            field("EE Fleetrock ID"; Rec."EE Fleetrock ID")
            {
                ApplicationArea = all;
            }
            field("EE Load Number"; Rec."EE Load Number")
            {
                ApplicationArea = all;
            }
        }
    }
}