pageextension 80014 "Customer Ledger Entries" extends "Customer Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("EE Load Number"; Rec."EE Load Number")
            {
                ApplicationArea = All;
            }
        }
    }
}