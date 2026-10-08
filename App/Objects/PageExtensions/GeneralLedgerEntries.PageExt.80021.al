pageextension 80021 "EE General Ledger Entries" extends "General Ledger Entries"
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
