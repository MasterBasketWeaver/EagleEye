pageextension 80020 "EE Posted Purch. Inv. Subform" extends "Posted Purch. Invoice Subform"
{
    layout
    {
        addafter(Description)
        {
            field("EE Description 2"; Rec."Description 2")
            {
                ApplicationArea = all;
            }
        }
    }
}