pageextension 80011 "EE Sales Invoice" extends "Sales Invoice"
{
    layout
    {
        addlast(General)
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