pageextension 80004 "EE Sales Invoice Subform" extends "Sales Invoice Subform"
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