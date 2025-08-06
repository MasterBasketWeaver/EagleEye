tableextension 80011 "EE Purch. Cr. Memo Hdr." extends "Purch. Cr. Memo Hdr."
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

    keys
    {
        key(FleetrockID; "EE Fleetrock ID") { }
    }
}