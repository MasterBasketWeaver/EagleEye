pageextension 80155 "EE Sales Rec. Setup2" extends "Sales & Receivables Setup"
{
    layout
    {
        addlast(General)
        {
            field("EE Default Payment Terms"; Rec."EE Default Payment Terms")
            {
                ApplicationArea = all;
                ShowMandatory = true;
            }
        }
    }
}