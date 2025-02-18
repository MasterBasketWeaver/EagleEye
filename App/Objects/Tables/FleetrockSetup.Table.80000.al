table 80000 "EE Fleetrock Setup"
{
    Caption = 'Fleetrock Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "EE Fleetrock Setup";
    LookupPageId = "EE Fleetrock Setup";

    fields
    {
        field(1; "Primary Key"; Code[1])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Integration URL"; Text[1024])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Username"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(4; "API Key"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(5; "API Token"; Text[256])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6; "API Token Expiry Date"; Date)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7; "Item G/L Account No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }
        field(8; "Vendor Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Vendor Posting Group".Code;
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