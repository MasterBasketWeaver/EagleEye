table 80008 "EE Claim Line"
{
    DataClassification = CustomerContent;
    Caption = 'Claim Line';
    LookupPageId = "EE Staged Claim Lines";
    DrillDownPageId = "EE Staged Claim Lines";


    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Header Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "EE Claim Header"."Entry No.";
        }
        field(3; "Header id"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; "type"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "ro_id"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; "task_id"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; "task_part_id"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; "part_id"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; "system_component_code"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(17; "description"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; "quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(19; "unit_price"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "claim_amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(21; "amount_paid"; Decimal)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(K2; "Header id", "Header Entry No.") { }
    }
}