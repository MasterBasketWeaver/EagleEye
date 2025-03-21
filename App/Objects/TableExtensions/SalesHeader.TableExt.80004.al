tableextension 80004 "EE Sales Header" extends "Sales Header"
{
    fields
    {
        field(80000; "EE Fleetrock ID"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Fleetrock ID';
        }
        field(80010; "EE Load Number"; Code[35])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Load Number';
        }
    }

    keys
    {
        key(FleetrockID; "EE Fleetrock ID") { }
    }
}