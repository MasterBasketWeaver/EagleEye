tableextension 80008 "EE Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(80000; "EE Part Id"; Text[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Part Id';
        }
    }
}