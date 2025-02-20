table 80003 "EE Fleetrock Import Entry"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; Type; Enum "EE Import Type")
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(3; "Success"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Error Message"; Text[250])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "Import Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = if (Type = const("Purchase Order")) "EE Purch. Header Staging"."Entry No.";
        }
        field(6; "Imported By"; Code[50])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field(SystemCreatedBy)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}