tableextension 80008 "EE Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(80000; "EE Part Id"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Part Id';
        }
        field(80001; "EE Staging Line Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Staging Line Entry No.';
            TableRelation = "EE Purch. Line Staging"."Entry No.";
        }
    }
}