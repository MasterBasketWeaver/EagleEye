tableextension 80005 "EE Sales Inv. Header" extends "Sales Invoice Header"
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