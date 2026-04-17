table 81000 "EE Fleetrock Audit Issue"
{
    Caption = 'Fleetrock Audit Issue';
    DataClassification = CustomerContent;
    LookupPageId = "EE Fleetrock Audit Issues";
    DrillDownPageId = "EE Fleetrock Audit Issues";

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Order Kind"; Enum "EE Fleetrock Order Kind")
        {
            Caption = 'Order Kind';
        }
        field(3; "Credential"; Text[50])
        {
            Caption = 'Credential';
        }
        field(4; "Order ID"; Code[30])
        {
            Caption = 'Order ID';
        }
        field(5; "Issue Code"; Enum "EE Fleetrock Issue Code")
        {
            Caption = 'Issue Code';
        }
        field(6; "Line Ref"; Text[50])
        {
            Caption = 'Line Reference';
        }
        field(7; "Part Number"; Text[50])
        {
            Caption = 'Part Number';
        }
        field(8; "Part Description"; Text[250])
        {
            Caption = 'Part Description';
        }
        field(9; Quantity; Text[30])
        {
            Caption = 'Quantity';
        }
        field(10; "Unit Price"; Text[30])
        {
            Caption = 'Unit Price';
        }
        field(11; "Expected Amount"; Decimal)
        {
            Caption = 'Expected Amount';
            AutoFormatType = 1;
        }
        field(12; "Actual Amount"; Decimal)
        {
            Caption = 'Actual Amount';
            AutoFormatType = 1;
        }
        field(13; Difference; Decimal)
        {
            Caption = 'Difference';
            AutoFormatType = 1;
        }
        field(14; Message; Text[2048])
        {
            Caption = 'Message';
        }
        field(15; "Refreshed At"; DateTime)
        {
            Caption = 'Refreshed At';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(OrderKey; "Order Kind", "Order ID", "Issue Code")
        {
        }
    }
}
