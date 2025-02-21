pageextension 80006 "EE Posted Sales Invoices" extends "Posted Sales Invoices"
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