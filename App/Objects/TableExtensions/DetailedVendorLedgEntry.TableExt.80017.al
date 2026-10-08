tableextension 80017 "EE Dtld. Vendor Ledg. Entry" extends "Detailed Vendor Ledg. Entry"
{
    fields
    {
        field(80000; "EE Fleetrock ID"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Fleetrock ID';
        }
    }
}
