page 80000 "EE Fleetrock Setup"
{
    SourceTable = "EE Fleetrock Setup";
    ApplicationArea = all;
    UsageCategory = Administration;
    Caption = 'Fleetrock Setup';
    Permissions = tabledata "Sales Invoice Header" = RIMD,
    tabledata "Sales Invoice Line" = RIMD,
    tabledata "Sales Shipment Header" = RIMD,
    tabledata "Sales Shipment Line" = RIMD,
    tabledata "Purch. Inv. Header" = RIMD,
    tabledata "Purch. Inv. Line" = RIMD,
    tabledata "Purch. Rcpt. Header" = RIMD,
    tabledata "Purch. Rcpt. Line" = RIMD,
    tabledata "Vendor Ledger Entry" = RIMD,
    tabledata "Detailed Vendor Ledg. Entry" = RIMD,
    tabledata "G/L Entry" = RIMD,
    tabledata "VAT Entry" = RIMD,
    tabledata "Cust. Ledger Entry" = RIMD,
    tabledata "Detailed Cust. Ledg. Entry" = RIMD,
    tabledata "Bank Account Ledger Entry" = RIMD,
    tabledata "G/L Entry - VAT Entry Link" = RIMD;

    layout
    {
        area(Content)
        {
            group("Purchase Orders")
            {
                field("Purchase Item No.";
                Rec."Purchase Item No.")
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
                field("Check Purch. Order DateFormula"; Rec."Check Purch. Order DateFormula")
                {
                    ApplicationArea = all;
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
                field("Check Repair Order DateFormula"; Rec."Check Repair Order DateFormula")
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
                field("Claims Parts G/L No."; Rec."Claims Parts G/L No.")
                {
                    ApplicationArea = all;
                    Caption = 'Parts G/L No.';
                }
                field("Claims Labor G/L No."; Rec."Claims Labor G/L No.")
                {
                    ApplicationArea = all;
                    Caption = 'Labor G/L No.';
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
                Enabled = not IsProduction;
                Visible = not IsProduction;

                trigger OnAction()
                var
                    ImportExportEntry: Record "EE Import/Export Entry";
                    PurchHeaderStaging: Record "EE Purch. Header Staging";
                    PurchLineStaging: Record "EE Purch. Line Staging";
                    SalesHeaderStaging: Record "EE Sales Header Staging";
                    TaskLineStaging: Record "EE Task Line Staging";
                    PartLineStaging: Record "EE Part Line Staging";
                    SalesHeader: Record "Sales Header";
                    SalesLine: Record "Sales Line";
                    SalesInvHeader: Record "Sales Invoice Header";
                    SalesInvLine: Record "Sales Invoice Line";
                    SalesShptHeader: Record "Sales Shipment Header";
                    SalesShptLine: Record "Sales Shipment Line";
                    PurchHeader: Record "Purchase Header";
                    PurchLine: Record "Purchase Line";
                    PurchRcptHeader: Record "Purch. Rcpt. Header";
                    PurchRcptLine: Record "Purch. Rcpt. Line";
                    PurchInvHeader: Record "Purch. Inv. Header";
                    PurchInvLine: Record "Purch. Inv. Line";
                    CustomerLedgerEntry: Record "Cust. Ledger Entry";
                    VendorLedgerEntry: Record "Vendor Ledger Entry";
                    DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                    GLAccountEntry: Record "G/L Entry";
                    BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
                    VATEntry: Record "VAT Entry";
                    GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
                begin
                    if IsProduction then
                        Error('Cannot clear logs in production environment.');
                    if not Confirm('Delete all log entries?') then
                        exit;
                    ImportExportEntry.DeleteAll(false);
                    PurchHeaderStaging.DeleteAll(false);
                    PurchLineStaging.DeleteAll(false);
                    SalesHeaderStaging.DeleteAll(false);
                    TaskLineStaging.DeleteAll(false);
                    PartLineStaging.DeleteAll(false);
                    SalesHeader.DeleteAll(false);
                    SalesLine.DeleteAll(false);
                    SalesInvHeader.DeleteAll(false);
                    SalesInvLine.DeleteAll(false);
                    SalesShptHeader.DeleteAll(false);
                    SalesShptLine.DeleteAll(false);
                    PurchHeader.DeleteAll(false);
                    PurchLine.DeleteAll(false);
                    PurchRcptHeader.DeleteAll(false);
                    PurchRcptLine.DeleteAll(false);
                    PurchInvHeader.DeleteAll(false);
                    PurchInvLine.DeleteAll(false);
                    CustomerLedgerEntry.DeleteAll(false);
                    VendorLedgerEntry.DeleteAll(false);
                    DetailedVendorLedgEntry.DeleteAll(false);
                    DetailedCustLedgEntry.DeleteAll(false);
                    GLAccountEntry.DeleteAll(false);
                    BankAccountLedgerEntry.DeleteAll(false);
                    VATEntry.DeleteAll(false);
                    GLEntryVATEntryLink.DeleteAll(false);
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

    var
        IsProduction: Boolean;

    trigger OnInit()
    var
        EnvInfo: Codeunit "Environment Information";
    begin
        IsProduction := EnvInfo.IsProduction();
    end;
}