pageextension 80010 "EE Customer List" extends "Customer List"
{
    layout
    {
        addlast(Control1)
        {
            field("EE Source Type"; Rec."EE Source Type")
            {
                ApplicationArea = all;
            }
            field("EE Source No."; Rec."EE Source No.")
            {
                ApplicationArea = all;
            }
        }
    }
}