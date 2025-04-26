tableextension 80152 "EEC Sales & Rec. Setup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(50100; "EEC Default Payment Terms"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Payment Terms';
            TableRelation = "Payment Terms".Code;
        }
    }
}