pageextension 80301 "EEMCP Vendor Card" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field("EEMCP Dot No."; Rec."EEMCP Dot No.")
            {
                ApplicationArea = all;
            }
        }
    }
}