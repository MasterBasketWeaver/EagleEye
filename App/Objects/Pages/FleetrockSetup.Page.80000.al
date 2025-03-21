page 80000 "EE Fleetrock Setup"
{
    SourceTable = "EE Fleetrock Setup";
    ApplicationArea = all;
    UsageCategory = Administration;
    Caption = 'Fleetrock Setup';

    layout
    {
        area(Content)
        {
            group("G/L Mappings")
            {
                group("Purchase Orders")
                {
                    field("Purchase Item No."; Rec."Purchase Item No.")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                }
                group("Repair Orders")
                {
                    field("Internal Customer Name"; Rec."Internal Customer Names")
                    {
                        ApplicationArea = all;
                    }
                    field("Internal Labor Item No."; Rec."Internal Labor Item No.")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                    field("Internal Parts Item No."; Rec."Internal Parts Item No.")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                    field("External Labor Item No."; Rec."External Labor Item No.")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                    field("External Parts Item No."; Rec."External Parts Item No.")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                }
            }

            group(Defaults)
            {
                field("Vendor Posting Group"; Rec."Vendor Posting Group")
                {
                    ApplicationArea = all;
                    ShowMandatory = true;
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = all;
                    ShowMandatory = true;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = all;
                    ShowMandatory = true;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = all;
                    ShowMandatory = true;
                }
                field("Payment Terms"; Rec."Payment Terms")
                {
                    ApplicationArea = all;
                    ShowMandatory = true;
                }
            }
            group(Integration)
            {
                field("Integration URL"; Rec."Integration URL")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Username"; Rec.Username)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("API Key"; Rec."API Key")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Earliest Import DateTime"; Rec."Earliest Import DateTime")
                {
                    ApplicationArea = all;
                }
                field("Use API Token"; Rec."Use API Token")
                {
                    ApplicationArea = all;
                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("API Token"; Rec."API Token")
                {
                    ApplicationArea = All;
                    Visible = Rec."Use API Token";
                }
                field("API Token Expiry Date"; Rec."API Token Expiry Date")
                {
                    ApplicationArea = all;
                    Visible = Rec."Use API Token";
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Refresh API Token")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Refresh;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                begin
                    Message(FleetrockMgt.CheckToGetAPIToken(Rec));
                    CurrPage.Update(false);
                end;
            }
            // action("Get Units")
            // {
            //     ApplicationArea = All;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     PromotedOnly = true;
            //     Image = Union;

            //     trigger OnAction()
            //     var
            //         FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
            //     begin
            //         FleetrockMgt.GetUnits();
            //     end;
            // }
            // action("Get Suppliers")
            // {
            //     ApplicationArea = All;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     PromotedOnly = true;
            //     Image = Vendor;

            //     trigger OnAction()
            //     var
            //         FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
            //         s: Text;
            //     begin
            //         FleetrockMgt.GetSuppliers().WriteTo(s);
            //         Message(s);
            //     end;
            // }
            action("Get Open POs")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Purchase;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                    s: Text;
                begin
                    FleetrockMgt.GetPurchaseOrders(Enum::"EE Purch. Order Status"::Open).WriteTo(s);
                    Message(s);
                end;
            }
            action("Get Closed POs")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Sales;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                    s: Text;
                begin
                    FleetrockMgt.GetPurchaseOrders(Enum::"EE Purch. Order Status"::Closed).WriteTo(s);
                    Message(s);
                end;
            }
            action("Import Closed POs")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ImportChartOfAccounts;

                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    Codeunit.Run(Codeunit::"EE Get Repair Orders")
                end;
            }
            action("Get Received POs By Date")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ImportChartOfAccounts;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                    s: Text;
                begin
                    FleetrockMgt.GetPurchaseOrders(0DT, s, Enum::"EE Event Type"::Received).WriteTo(s);
                    Message(s);
                end;
            }
            action("Get Closed POs By Date")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ImportChartOfAccounts;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                    s: Text;
                begin
                    FleetrockMgt.GetPurchaseOrders(0DT, s, Enum::"EE Event Type"::Closed).WriteTo(s);
                    Message(s);
                end;
            }
            action("Get Closed ROs By Date")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ImportChartOfAccounts;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                    s: Text;
                    Status: Enum "EE Repair Order Status";
                    i: Integer;
                begin
                    i := StrMenu('Started,Invoiced');
                    case i of
                        1:
                            Status := Status::started;
                        2:
                            Status := Status::invoiced;
                    end;
                    FleetrockMgt.GetRepairOrders(0DT, Status, s).WriteTo(s);
                    Message(s);
                end;
            }
            action("Import ROs")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ImportCodes;

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"EE Get Repair Orders");
                end;
            }
            action("Clear Logs")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = DeleteAllBreakpoints;

                trigger OnAction()
                var
                    ImportExportEntry: Record "EE Import/Export Entry";
                    PurchHeaderStaging: Record "EE Purch. Header Staging";
                    PurchLineStaging: Record "EE Purch. Line Staging";
                    SalesHeaderStaging: Record "EE Sales Header Staging";
                    TaskLineStaging: Record "EE Task Line Staging";
                    PartLineStaging: Record "EE Part Line Staging";
                    SalesHeader: Record "Sales Header";
                begin
                    if not Confirm('Delete all log entries?') then
                        exit;
                    ImportExportEntry.DeleteAll(false);
                    PurchHeaderStaging.DeleteAll(false);
                    PurchLineStaging.DeleteAll(false);
                    SalesHeaderStaging.DeleteAll(false);
                    TaskLineStaging.DeleteAll(false);
                    PartLineStaging.DeleteAll(false);
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                    SalesHeader.SetRange("Sell-to Customer No.", '');
                    SalesHeader.DeleteAll(true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(true);
        end;
    end;
}