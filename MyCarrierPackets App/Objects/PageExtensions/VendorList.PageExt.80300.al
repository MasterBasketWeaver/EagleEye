pageextension 80300 "EEMCP Vendors" extends "Vendor List"
{
    layout
    {
        addlast(Control1)
        {
            field("EEMCP Dot No."; Rec."EEMCP Dot No.")
            {
                ApplicationArea = all;
            }
        }
    }
}