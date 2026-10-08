tableextension 80013 "EE G/L Entry" extends "G/L Entry"
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
