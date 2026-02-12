table 80009 "EE Unit Type Mapping"
{
    DataClassification = CustomerContent;
    Caption = 'Unit Type Mapping';
    LookupPageId = "EE Unit Type Mappings";
    DrillDownPageId = "EE Unit Type Mappings";

    fields
    {
        field(1; "Unit Type"; Enum "EE Unit Type")
        {

        }
        field(2; "G/L Account No."; Code[20])
        {
            TableRelation = "G/L Account"."No.";
            NotBlank = true;
        }
    }

    keys
    {
        key(PK; "Unit Type", "G/L Account No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if Rec."Unit Type" = Rec."Unit Type"::" " then
            Error(NoUnitTypeErr);
    end;

    var
        NoUnitTypeErr: Label 'Unit Type must be specified.';
}