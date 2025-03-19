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
        field(80005; "EE Sent Payment"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Sent Payment';
        }
        field(80006; "EE Sent Payment DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Sent Payment DateTime';
        }
    }

    keys
    {
        key(FleetrockID; "EE Fleetrock ID") { }
    }
}