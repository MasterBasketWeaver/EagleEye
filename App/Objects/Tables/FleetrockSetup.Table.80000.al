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
        field(7; "Purchase Item No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Item"."No.";
        }
        field(8; "Vendor Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Vendor Posting Group".Code;
        }
        field(9; "Tax Area Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Tax Area".Code;
        }

        field(11; "Use API Token"; boolean)
        {
            DataClassification = CustomerContent;
        }
        field(12; "Earliest Import DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(13; "Tax Jurisdiction Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "Tax Jurisdiction".Code;
        }

        field(14; "Customer Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Customer Posting Group".Code;
        }
        field(15; "Payment Terms"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "Payment Terms".Code;
        }

        field(20; "Internal Labor Item No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Item"."No.";
        }
        field(21; "Internal Parts Item No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Item"."No.";
        }
        field(22; "External Labor Item No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Item"."No.";
        }
        field(23; "External Parts Item No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Item"."No.";
        }
        field(24; "Internal Customer Names"; Text[1024])
        {
            DataClassification = CustomerContent;
        }

        field(33; "Vendor Username"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(34; "Vendor API Key"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(35; "Vendor API Token"; Text[256])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(40; "Additional Fee's G/L No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No." where(Blocked = const(false), "Account Type" = const(Posting));
        }
        // field(41; "Administration G/L No."; Code[20])
        // {
        //     DataClassification = CustomerContent;
        //     TableRelation = "G/L Account"."No." where(Blocked = const(false), "Account Type" = const(Posting));
        // }
        // field(42; "Diagnostic G/L No."; Code[20])
        // {
        //     DataClassification = CustomerContent;
        //     TableRelation = "G/L Account"."No." where(Blocked = const(false), "Account Type" = const(Posting));
        // }
        field(50; "Labor Cost"; Decimal)
        {
            DataClassification = CustomerContent;
            MinValue = 0;
            DecimalPlaces = 0 : 2;
        }
        field(51; "Labor Tax Group Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Tax Group".Code;
        }
        field(52; "Parts Tax Group Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Tax Group".Code;
        }
        field(53; "Fees Tax Group Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Tax Group".Code;
        }
        field(54; "Non-Taxable Tax Group Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Tax Group".Code;
        }
        field(60; "Auto-post Repair Orders"; Boolean)
        {
            DataClassification = CustomerContent;
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