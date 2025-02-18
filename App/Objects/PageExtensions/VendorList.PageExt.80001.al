pageextension 80001 "EE Vendor List" extends "Vendor List"
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