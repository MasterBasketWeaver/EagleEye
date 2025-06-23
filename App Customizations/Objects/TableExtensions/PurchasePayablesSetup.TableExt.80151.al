tableextension 80151 "EEC Purchase Payables Setup" extends "Purchases & Payables Setup"
{
    fields
    {
        field(80150; "EEC ACH Payment Method"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'ACH Payment Method';
            TableRelation = "Payment Method".Code;
        }
        field(50151; "EEC Default Payment Terms"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Payment Terms';
            TableRelation = "Payment Terms".Code;
        }

        field(50152; "EEC Default Vend. Post. Group"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Vendor Posting Group';
            TableRelation = "Vendor Posting Group".Code;
        }
        field(50153; "EEC Default Payment Method"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Payment Method';
            TableRelation = "Payment Method".Code;
        }
        field(80154; "EEC Check Payment Method"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Check Payment Method';
            TableRelation = "Payment Method".Code;
        }
    }
}