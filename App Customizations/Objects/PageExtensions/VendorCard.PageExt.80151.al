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
        modify("Payment Terms Code")
        {
            trigger OnBeforeValidate()
            begin
                Rec."EEC Updated Payment Terms" := true;
            end;
        }
        modify("Payment Method Code")
        {
            trigger OnBeforeValidate()
            begin
                Rec."EEC Updated Payment Method" := true;
            end;
        }
    }
}