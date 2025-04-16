tableextension 80006 "EE Sales Line" extends "Sales Line"
{
    fields
    {
        field(80000; "EE Task/Part Id"; Text[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Task/Part Id';
        }
        field(80001; "EE Updated"; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Updated';
        }
    }
}