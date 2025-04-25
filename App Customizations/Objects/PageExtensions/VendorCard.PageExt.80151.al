pageextension 80151 "EE Vendor Card2" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field("EE Non-Mandatory Ext. Doc. No."; Rec."EE Non-Mandatory Ext. Doc. No.")
            {
                ApplicationArea = all;
            }
        }
    }
}