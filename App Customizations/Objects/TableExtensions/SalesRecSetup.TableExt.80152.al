tableextension 80152 "EE Sales & Rec. Setup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(50100; "EE Default Payment Terms"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Payment Terms';
            TableRelation = "Payment Terms".Code;
        }
    }
}