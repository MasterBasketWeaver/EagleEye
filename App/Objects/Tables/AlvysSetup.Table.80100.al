table 80100 "EE Alvys Setup"
{
    Caption = 'Alvys Setup';
    DataClassification = CustomerContent;
    // DrillDownPageId = "EE Fleetrock Setup";
    // LookupPageId = "EE Fleetrock Setup";

    fields
    {
        field(1; "Primary Key"; Code[1])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Integration URL"; Text[128])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Tenant ID"; Text[10])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Client ID"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Client Secret"; Text[90])
        {
            DataClassification = CustomerContent;
        }
        field(6; "API Token"; Text[256])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7; "API Token Expiry DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}