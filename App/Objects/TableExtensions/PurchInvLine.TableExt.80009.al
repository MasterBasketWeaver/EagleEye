tableextension 80009 "EE Purch. Inv. Line" extends "Purch. Inv. Line"
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