page 80003 "EE Fleetrock Entries"
{
    SourceTable = "EE Import/Export Entry";
    ApplicationArea = all;
    UsageCategory = Administration;
    Caption = 'Fleetrock Import/Export Entries';
    Editable = false;
    LinksAllowed = false;
    AnalysisModeEnabled = false;
    PageType = List;
    SourceTableView = sorting("Entry No.") order(descending);

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
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = all;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Event Type"; Rec."Event Type")
                {
                    ApplicationArea = all;
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
                    BlankZero = true;

                    trigger OnDrillDown()
                    var
                        PurchHeaderStaging: Record "EE Purch. Header Staging";
                        SalesHeaderStaging: Record "EE Sales Header Staging";
                    begin
                        if Rec."Import Entry No." <> 0 then
                            case Rec."Document Type" of
                                Rec."Document Type"::"Purchase Order":
                                    if PurchHeaderStaging.Get(Rec."Import Entry No.") then
                                        Page.Run(Page::"EE Staged Purchased Headers", PurchHeaderStaging);
                                Rec."Document Type"::"Repair Order":
                                    if SalesHeaderStaging.Get(Rec."Import Entry No.") then
                                        Page.Run(0, SalesHeaderStaging);
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
                field(URL; Rec.URL)
                {
                    ApplicationArea = all;
                }
                field(Method; Rec.Method)
                {
                    ApplicationArea = all;
                }
                field("Request Body"; Rec."Request Body")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Show Error Message")
            {
                ApplicationArea = all;
                Image = ErrorLog;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Enabled = Rec."Error Message" <> '';

                trigger OnAction()
                begin
                    Message(Rec."Error Message");
                end;
            }
            action("Show URL")
            {
                ApplicationArea = all;
                Image = LaunchWeb;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Enabled = Rec.URL <> '';

                trigger OnAction()
                begin
                    Message(Rec.URL);
                end;
            }
            action("Show Request Body")
            {
                ApplicationArea = all;
                Image = WorkCenterAbsence;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Enabled = Rec."Request Body" <> '';

                trigger OnAction()
                begin
                    Message(Rec."Request Body");
                end;
            }
        }
    }
}