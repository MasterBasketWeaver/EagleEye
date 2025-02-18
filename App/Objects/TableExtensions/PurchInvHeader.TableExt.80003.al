tableextension 80003 "EE Purch. Inv. Header" extends "Purch. Inv. Header"
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