pageextension 80014 "EE Customer Ledger Entries" extends "Customer Ledger Entries"
{
    layout
    {
        addafter("Document No.")
        {
            field("EE Fleetrock ID"; Rec."EE Fleetrock ID")
            {
                ApplicationArea = all;
            }
        }
    }
}
