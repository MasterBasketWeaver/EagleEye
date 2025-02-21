pageextension 80012 "EE Sales Invoice List" extends "Sales Invoice List"
{
    layout
    {
        addlast(Control1)
        {
            field("EE Fleetrock ID"; Rec."EE Fleetrock ID")
            {
                ApplicationArea = all;
            }
        }
    }
}