tableextension 80153 "EEC Sales Header" extends "Sales Header"
{
    fields
    {
        field(80150; "EEC Updated Payment Terms"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Updated Payment Terms';
            Editable = false;
        }
    }
}