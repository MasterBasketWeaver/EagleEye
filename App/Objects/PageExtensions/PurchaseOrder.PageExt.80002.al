pageextension 80002 "EE Purchase Order" extends "Purchase Order"
{
    layout
    {
        addlast(General)
        {
            field("EE Fleetrock ID"; Rec."EE Fleetrock ID")
            {
                ApplicationArea = all;
            }
        }
    }
}