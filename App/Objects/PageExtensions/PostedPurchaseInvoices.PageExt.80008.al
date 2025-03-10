pageextension 80008 "EE Posted Purchase Invoices" extends "Posted Purchase Invoices"
{
    layout
    {
        addafter("No.")
        {
            field("EE Fleetrock ID"; Rec."EE Fleetrock ID")
            {
                ApplicationArea = all;
            }
        }
    }
}