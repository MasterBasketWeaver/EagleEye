tableextension 80007 "EE Sales Invoice Line" extends "Sales Invoice Line"
{
    fields
    {
        field(80000; "EE Task/Part Id"; Text[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Task/Part Id';
        }
    }
}