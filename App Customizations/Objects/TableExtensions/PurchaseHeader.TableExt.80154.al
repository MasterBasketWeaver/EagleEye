tableextension 80154 "EEC Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(80150; "EEC Updated Payment Terms"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Updated Payment Terms';
            Editable = false;
        }
        field(80151; "EEC Updated Payment Method"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Updated Payment Method';
            Editable = false;
        }
    }
}