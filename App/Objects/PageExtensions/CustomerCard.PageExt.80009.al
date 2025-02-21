pageextension 80009 "EE Customer Card" extends "Customer Card"
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