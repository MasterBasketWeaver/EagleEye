page 80009 "EE Staged Claim Lines"
{
    PageType = List;
    SourceTable = "EE Claim Line";
    Caption = 'Staged Claim Lines';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    LinksAllowed = false;
    AnalysisModeEnabled = false;

    layout
    {
        area(Content)
        {
            repeater(Line)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = all;
                }
                field("Header Entry No."; Rec."Header Entry No.")
                {
                    ApplicationArea = all;
                }
                field("Header id"; Rec."Header id")
                {
                    ApplicationArea = all;
                }
                field("type"; Rec."type")
                {
                    ApplicationArea = all;
                }
                field("ro_id"; Rec."ro_id")
                {
                    ApplicationArea = all;
                }
                field("task_id"; Rec."task_id")
                {
                    ApplicationArea = all;
                }
                field("task_part_id"; Rec."task_part_id")
                {
                    ApplicationArea = all;
                }
                field("part_id"; Rec."part_id")
                {
                    ApplicationArea = all;
                }
                field("system_component_code"; Rec."system_component_code")
                {
                    ApplicationArea = all;
                }
                field("description"; Rec."description")
                {
                    ApplicationArea = all;
                }
                field("quantity"; Rec."quantity")
                {
                    ApplicationArea = all;
                }
                field("unit_price"; Rec."unit_price")
                {
                    ApplicationArea = all;
                }
                field("claim_amount"; Rec."claim_amount")
                {
                    ApplicationArea = all;
                }
                field("amount_paid"; Rec."amount_paid")
                {
                    ApplicationArea = all;
                }
            }
        }
    }
}