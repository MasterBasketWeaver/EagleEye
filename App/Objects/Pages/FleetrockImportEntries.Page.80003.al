page 80003 "EE Fleetrock Import Entries"
{
    SourceTable = "EE Fleetrock Import Entry";
    ApplicationArea = all;
    UsageCategory = Administration;
    Caption = 'Fleetrock Import Entries';
    Editable = false;
    LinksAllowed = false;
    AnalysisModeEnabled = false;
    PageType = List;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = all;
                    Caption = 'Imported At';
                }
                field("Imported By"; Rec."Imported By")
                {
                    ApplicationArea = all;
                }
                field("Import Entry No."; Rec."Import Entry No.")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the Entry No. of the related staging table record that holds th import data.';

                    trigger OnDrillDown()
                    var
                        PurchHeaderStaging: Record "EE Purch. Header Staging";
                    begin
                        if Rec."Import Entry No." <> 0 then
                            case Rec.Type of
                                Rec.Type::"Purchase Order":
                                    if PurchHeaderStaging.Get(Rec."Import Entry No.") then
                                        Page.Run(Page::"EE Staged Purchased Headers", PurchHeaderStaging);
                            end;
                    end;
                }
                field("Success"; Rec."Success")
                {
                    ApplicationArea = all;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = all;
                }
            }
        }
    }
}