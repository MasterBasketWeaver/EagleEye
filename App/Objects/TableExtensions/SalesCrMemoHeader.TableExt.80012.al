tableextension 80012 "EE Sales Cr.Memo Header" extends "Sales Cr.Memo Header"
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