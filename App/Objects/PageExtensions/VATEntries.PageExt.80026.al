pageextension 80026 "EE VAT Entries" extends "VAT Entries"
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
