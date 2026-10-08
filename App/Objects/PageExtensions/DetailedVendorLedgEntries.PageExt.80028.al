pageextension 80028 "EE Dtld. Vendor Ledg. Entries" extends "Detailed Vendor Ledg. Entries"
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
