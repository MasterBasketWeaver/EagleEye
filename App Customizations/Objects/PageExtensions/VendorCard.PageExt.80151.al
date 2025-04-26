pageextension 80151 "EEC Vendor Card2" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field("EE Non-Mandatory Ext. Doc. No."; Rec."EEC NonMandatory Ext. Doc. No.")
            {
                ApplicationArea = all;
            }
        }
    }
}