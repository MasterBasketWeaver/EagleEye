pageextension 80012 "EE Sales Invoice List" extends "Sales Invoice List"
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