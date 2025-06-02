pageextension 80015 "EE Apply Customer Entries" extends "Apply Customer Entries"
{
    layout
    {
        addafter("Document No.")
        {
            field("EE Load Number"; Rec."EE Load Number")
            {
                ApplicationArea = All;
            }
        }
    }
}