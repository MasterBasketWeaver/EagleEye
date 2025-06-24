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

            group("Purchase Orders")
            {
                field("Purchase Item No."; Rec."Purchase Item No.")
                {
                    ApplicationArea = all;
                    ShowMandatory = true;
                }
                field("Auto-post Purchase Orders"; Rec."Auto-post Purchase Orders")
                {
                    ApplicationArea = all;
                }
                field("Import Repairs as Purchases"; Rec."Import Repairs as Purchases")
                {
                    ApplicationArea = all;
                    ToolTip = 'If enabled, the Repair Orders will be imported as Purchase Orders.';
                }
                field("Import Vendor Details"; Rec."Import Vendor Details")
                {
                    ApplicationArea = all;
                    ToolTip = 'If enabled, the vendor details will be imported from Fleetrock and used to create a vendor account in Business Central.';
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
                field("Labor Cost"; Rec."Labor Cost")
                {
                    ApplicationArea = all;
                }
                field("Additional Fee's G/L No."; Rec."Additional Fee's G/L No.")
                {
                    ApplicationArea = all;
                }
                field("Auto-post Repair Orders"; Rec."Auto-post Repair Orders")
                {
                    ApplicationArea = all;
                }
                field("Import Repair with Vendor"; Rec."Import Repair with Vendor")
                {
                    ApplicationArea = all;
                }
            }
            group(Claims)
            {
                field("Claims Journal Template"; Rec."Claims Journal Template")
                {
                    ApplicationArea = all;
                    Caption = 'Journal Template';
                }
                field("Claims Journal Batch"; Rec."Claims Journal Batch")
                {
                    ApplicationArea = all;
                    Caption = 'Journal Batch';
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
                field("Payment Terms"; Rec."Payment Terms")
                {
                    ApplicationArea = all;
                    ShowMandatory = true;
                }
                group("Taxes")
                {
                    field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                    field("Tax Area Code"; Rec."Tax Area Code")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                    field("Labor Tax Group Code"; Rec."Labor Tax Group Code")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                    field("Parts Tax Group Code"; Rec."Parts Tax Group Code")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                    field("Fees Tax Group Code"; Rec."Fees Tax Group Code")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                    field("Non-Taxable Tax Group Code"; Rec."Non-Taxable Tax Group Code")
                    {
                        ApplicationArea = all;
                        ShowMandatory = true;
                    }
                }
            }
            group(Integration)
            {
                field("Integration URL"; Rec."Integration URL")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Earliest Import DateTime"; Rec."Earliest Import DateTime")
                {
                    ApplicationArea = all;
                }
                field("Import Tag"; Rec."Import Tags")
                {
                    ApplicationArea = all;
                }
                group("Customer Account")
                {
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
                }
                group("Vendor Account")
                {
                    field("Vendor Username"; Rec."Vendor Username")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Vendor API Key"; Rec."Vendor API Key")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Vendor API Token"; Rec."Vendor API Token")
                    {
                        ApplicationArea = All;
                        Visible = Rec."Use API Token";
                    }
                }
                group(Token)
                {
                    // field("Use API Token"; Rec."Use API Token")
                    // {
                    //     ApplicationArea = all;
                    //     trigger OnValidate()
                    //     begin
                    //         CurrPage.Update(false);
                    //     end;
                    // }
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
                    Message('Default: %1\Vendor: %2', FleetrockMgt.CheckToGetAPIToken(Rec), FleetrockMgt.CheckToGetAPIToken(Rec, true));
                    CurrPage.Update(false);
                end;
            }

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
            // action("Get Specific PO")
            // {
            //     ApplicationArea = All;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     PromotedOnly = true;
            //     Image = Purchasing;

            //     trigger OnAction()
            //     var
            //         FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
            //         GetDocNo: Page "EE Get Doc. No.";
            //         DocNo, s : Text;
            //     begin
            //         GetDocNo.RunModal();
            //         DocNo := GetDocNo.GetDocNo();
            //         if DocNo = '' then
            //             exit;
            //         FleetrockMgt.GetPurchaseOrder(DocNo).WriteTo(s);
            //         Message(s);
            //     end;
            // }

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
                    SalesShptHeader: Record "Sales Shipment Header";
                    SalesInvHeader: Record "Sales Invoice Header";
                    PurchHeader: Record "Purchase Header";
                    PurchRcptHeader: Record "Purch. Rcpt. Header";
                    PurchInvHeader: Record "Purch. Inv. Header";
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
                    SalesHeader.Reset();
                    SalesHeader.SetFilter("EE Fleetrock ID", '<>%1', '');
                    SalesHeader.DeleteAll(true);
                    PurchHeader.SetFilter("EE Fleetrock ID", '<>%1', '');
                    PurchHeader.DeleteAll(true);
                    SalesInvHeader.SetFilter("EE Fleetrock ID", '<>%1', '');
                    SalesShptHeader.SetCurrentKey("Order No.");
                    if SalesInvHeader.FindSet() then
                        repeat
                            SalesShptHeader.SetRange("Order No.", SalesInvHeader."Order No.");
                            SalesShptHeader.DeleteAll(true);
                            SalesInvHeader."No. Printed" := 1;
                            SalesInvHeader.Delete(true);
                        until SalesInvHeader.Next() = 0;
                    PurchInvHeader.SetFilter("EE Fleetrock ID", '<>%1', '');
                    PurchRcptHeader.SetCurrentKey("Order No.");
                    if PurchInvHeader.FindSet() then
                        repeat
                            PurchRcptHeader.SetRange("Order No.", PurchInvHeader."Order No.");
                            PurchRcptHeader.DeleteAll(true);
                            PurchInvHeader.Delete(true);
                        until PurchInvHeader.Next() = 0;
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