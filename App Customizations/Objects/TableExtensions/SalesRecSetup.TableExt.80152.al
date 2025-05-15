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
        field(50101; "EEC Default Cust. Post. Group"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Customer Posting Group';
            TableRelation = "Customer Posting Group".Code;
        }
        field(50102; "EEC Default Tax Area Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Tax Area Code';
            TableRelation = "Tax Area".Code;
        }
    }
}