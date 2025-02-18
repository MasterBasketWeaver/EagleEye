pageextension 80000 "EE Vendor Card" extends "Vendor Card"
{
    layout
    {
        addlast(General)
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