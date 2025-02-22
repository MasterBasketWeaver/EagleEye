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
            group(Defaults)
            {
                field("Purchase G/L Account No."; Rec."Purchase G/L Account No.")
                {
                    ApplicationArea = all;
                    ShowMandatory = true;
                }
                field("Repair G/L Account No."; Rec."Repair G/L Account No.")
                {
                    ApplicationArea = all;
                    ShowMandatory = true;
                }
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
                begin
                    Codeunit.Run(Codeunit::"EE Get Closed Purch. Orders")
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
                    FleetrockMgt.GetClosedPurchaseOrders(0DT, s).WriteTo(s);
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