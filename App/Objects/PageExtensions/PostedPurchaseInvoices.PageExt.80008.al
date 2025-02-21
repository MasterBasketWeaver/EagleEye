pageextension 80008 "EE Posted Purchase Invoices" extends "Posted Purchase Invoices"
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