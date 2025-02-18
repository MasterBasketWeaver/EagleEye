pageextension 80003 "EE Purchase Order List" extends "Purchase Order List"
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