pageextension 80013 "EE Posted Sales Inv. Subform" extends "Posted Sales Invoice Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("EE Task/Part Id"; Rec."EE Task/Part Id")
            {
                ApplicationArea = all;
            }
        }
    }
}