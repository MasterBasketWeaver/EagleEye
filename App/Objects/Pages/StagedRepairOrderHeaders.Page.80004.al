page 80004 "EE Staged Repair Order Headers"
{
    ApplicationArea = all;
    SourceTable = "EE Sales Header Staging";
    UsageCategory = Lists;
    Caption = 'Staged Repair Order Headers';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTableView = sorting("Entry No.") order(descending);

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
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = all;

                    trigger OnDrillDown()
                    var
                        SalesHeader: Record "Sales Header";
                        SalesInvHeader: Record "Sales Invoice Header";
                    begin
                        if Rec."Document No." <> '' then
                            if SalesHeader.Get(SalesHeader."Document Type"::Invoice, Rec."Document No.") then
                                Page.Run(Page::"Sales Invoice", SalesHeader)
                            else begin
                                SalesInvHeader.SetCurrentKey("Order No.");
                                SalesInvHeader.SetRange("Order No.", Rec."Document No.");
                                if not SalesInvHeader.FindFirst() then begin
                                    SalesInvHeader.Reset();
                                    SalesInvHeader.SetCurrentKey("Pre-Assigned No.");
                                    SalesInvHeader.SetRange("Pre-Assigned No.", Rec."Document No.");
                                    if not SalesInvHeader.FindFirst() then
                                        exit;
                                end;
                                Page.Run(Page::"Posted Sales Invoice", SalesInvHeader);
                            end;
                    end;
                }
                field("Purch. Staging Entry No."; Rec."Purch. Staging Entry No.")
                {
                    ApplicationArea = all;
                    Visible = ShowPurchDocNo;
                }
                field("Purch. Document No."; Rec."Purch. Document No.")
                {
                    ApplicationArea = all;
                    Visible = ShowPurchDocNo;

                    trigger OnDrillDown()
                    var
                        PurchaseHeader: Record "Purchase Header";
                        PurchInvHeader: Record "Purch. Inv. Header";
                    begin
                        if Rec."Purch. Document No." <> '' then
                            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."Purch. Document No.") then
                                Page.Run(Page::"Purchase Order", PurchaseHeader)
                            else begin
                                PurchInvHeader.SetCurrentKey("Order No.");
                                PurchInvHeader.SetRange("Order No.", Rec."Purch. Document No.");
                                if not PurchInvHeader.FindFirst() then begin
                                    PurchInvHeader.Reset();
                                    PurchInvHeader.SetCurrentKey("Pre-Assigned No.");
                                    PurchInvHeader.SetRange("Pre-Assigned No.", Rec."Purch. Document No.");
                                    if not PurchInvHeader.FindFirst() then
                                        exit;
                                end;
                                Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
                            end;
                    end;
                }
                field("Event Type"; Rec."Event Type")
                {
                    ApplicationArea = all;
                }
                field(id; Rec.id)
                {
                    ApplicationArea = all;
                }
                field("Task Lines"; Rec."Task Lines")
                {
                    ApplicationArea = all;
                }
                field("Part Lines"; Rec."Part Lines")
                {
                    ApplicationArea = all;
                }
                field(group; Rec.group)
                {
                    ApplicationArea = all;
                }
                field(ro_group_hierarchy; Rec.ro_group_hierarchy)
                {
                    ApplicationArea = all;
                }
                field(vin; Rec.vin)
                {
                    ApplicationArea = all;
                }
                field(unit_number; Rec.unit_number)
                {
                    ApplicationArea = all;
                }
                field(unit_type; Rec.unit_type)
                {
                    ApplicationArea = all;
                }
                field(custom_asset_id; Rec.custom_asset_id)
                {
                    ApplicationArea = all;
                }
                field(vendor_name; Rec.vendor_name)
                {
                    ApplicationArea = all;
                }
                field(vendor_company_id; Rec.vendor_company_id)
                {
                    ApplicationArea = all;
                }
                field(vendor_city; Rec.vendor_city)
                {
                    ApplicationArea = all;
                }
                field(vendor_state; Rec.vendor_state)
                {
                    ApplicationArea = all;
                }
                field(vendor_province; Rec.vendor_province)
                {
                    ApplicationArea = all;
                }
                field(vendor_zip_code; Rec.vendor_zip_code)
                {
                    ApplicationArea = all;
                }
                field(vendor_timezone; Rec.vendor_timezone)
                {
                    ApplicationArea = all;
                }
                field("Internal Customer"; Rec."Internal Customer")
                {
                    ApplicationArea = all;
                }
                field(customer_name; Rec.customer_name)
                {
                    ApplicationArea = all;
                }
                field(customer_company_id; Rec.customer_company_id)
                {
                    ApplicationArea = all;
                }
                field(odometer_miles; Rec.odometer_miles)
                {
                    ApplicationArea = all;
                }
                field(engine_hours; Rec.engine_hours)
                {
                    ApplicationArea = all;
                }
                field(priority_code; Rec.priority_code)
                {
                    ApplicationArea = all;
                }
                field(cost_center; Rec.cost_center)
                {
                    ApplicationArea = all;
                }
                field(tag; Rec.tag)
                {
                    ApplicationArea = all;
                }
                field(status; Rec.status)
                {
                    ApplicationArea = all;
                }
                field(created_by; Rec.created_by)
                {
                    ApplicationArea = all;
                }
                field(date_created; Rec.date_created)
                {
                    ApplicationArea = all;
                }
                field(date_started; Rec.date_started)
                {
                    ApplicationArea = all;
                }
                field(date_expected_finish; Rec.date_expected_finish)
                {
                    ApplicationArea = all;
                }
                field(date_finished; Rec.date_finished)
                {
                    ApplicationArea = all;
                }
                field(date_invoiced; Rec.date_invoiced)
                {
                    ApplicationArea = all;
                }
                field(date_invoice_paid; Rec.date_invoice_paid)
                {
                    ApplicationArea = all;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = all;
                }
                field("Started At"; Rec."Started At")
                {
                    ApplicationArea = all;
                }
                field("Expected Finish At"; Rec."Expected Finish At")
                {
                    ApplicationArea = all;
                }
                field("Finished At"; Rec."Finished At")
                {
                    ApplicationArea = all;
                }
                field("Invoiced At"; Rec."Invoiced At")
                {
                    ApplicationArea = all;
                }
                field("Invoice Paid At"; Rec."Invoice Paid At")
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
                field(po_number; Rec.po_number)
                {
                    ApplicationArea = all;
                }
                field(labor_total; Rec.labor_total)
                {
                    ApplicationArea = all;
                }
                field(part_total; Rec.part_total)
                {
                    ApplicationArea = all;
                }
                field(additional_charges; Rec.additional_charges)
                {
                    ApplicationArea = all;
                }
                field(additional_charges_tax_rate; Rec.additional_charges_tax_rate)
                {
                    ApplicationArea = all;
                }
                field(tax_total; Rec.tax_total)
                {
                    ApplicationArea = all;
                }
                field(credit_amount; Rec.credit_amount)
                {
                    ApplicationArea = all;
                }
                field(estimate; Rec.estimate)
                {
                    ApplicationArea = all;
                }
                field(estimate_accept_amount; Rec.estimate_accept_amount)
                {
                    ApplicationArea = all;
                }
                field(grand_total; Rec.grand_total)
                {
                    ApplicationArea = all;
                }
                field(paid_amount; Rec.paid_amount)
                {
                    ApplicationArea = all;
                }
                field(remit_to; Rec.remit_to)
                {
                    ApplicationArea = all;
                }
                field(remit_to_company_id; Rec.remit_to_company_id)
                {
                    ApplicationArea = all;
                }
                field("Import Error"; Rec."Import Error")
                {
                    ApplicationArea = all;
                }
                field("Processed Error"; Rec."Processed Error")
                {
                    ApplicationArea = all;
                }
                field("Processed"; Rec."Processed")
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

    actions
    {
        area(Processing)
        {
            action("Show Error Message")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Error;
                Enabled = not Rec.Processed;
                trigger OnAction()
                var
                    FleetrockEntry: Record "EE Import/Export Entry";
                begin
                    if Rec."Error Message" = '' then begin
                        FleetrockEntry.SetRange("Document Type", FleetrockEntry."Document Type"::"Repair Order");
                        FleetrockEntry.SetRange("Import Entry No.", Rec."Entry No.");
                        FleetrockEntry.SetRange(Success, false);
                        if FleetrockEntry.FindFirst() then
                            FleetrockEntry.DisplayErrorMessage();
                    end else
                        Message(Rec."Error Message");
                end;
            }
            action("Create Invoice")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Invoice;

                trigger OnAction()
                var
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                    SalesHeader: Record "Sales Header";
                begin
                    FleetrockMgt.CreateSalesOrder(Rec);
                    SalesHeader.SetRange("EE Fleetrock ID", Rec.id);
                    SalesHeader.FindLast();
                    Page.Run(Page::"Sales Invoice", SalesHeader);
                end;
            }
            action("Import Single Repair Order")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = DocumentEdit;

                trigger OnAction()
                var
                    GetDocNo: Page "EE Get Doc. No.";
                    DocNo: Text;
                    UseVendorAccount: Boolean;
                begin
                    GetDocNo.LookupMode(true);
                    if GetDocNo.RunModal() <> Action::LookupOK then
                        exit;
                    DocNo := GetDocNo.GetDocNo();
                    if DocNo = '' then
                        exit;
                    FleetrockSetup.Get();
                    if FleetrockSetup."Vendor API Token" <> '' then
                        UseVendorAccount := Confirm('Use %1 account?', false, FleetrockSetup."Vendor Username")
                    else
                        UseVendorAccount := false;
                    FleetrockMgt.GetAndImportRepairOrder(DocNo, UseVendorAccount);
                end;
            }
            action("Create Purchase Order")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Order;

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                    FleetrockSetup: Record "EE Fleetrock Setup";
                    PurchaseHeaderStaging: Record "EE Purch. Header Staging";

                    GetPurchaseOrders: Codeunit "EE Get Purchase Orders";
                    Result: Boolean;
                begin
                    FleetrockSetup.Get();
                    FleetrockSetup."Auto-post Purchase Orders" := false;
                    if FleetrockMgt.TryToCreatePurchaseStagingFromRepairStaging(Rec, PurchaseHeaderStaging) then
                        Result := GetPurchaseOrders.UpdateAndPostPurchaseOrder(FleetrockSetup, PurchaseHeaderStaging);
                    // Page.Run(0, PurchaseHeaderStaging);
                    if not Result then
                        Error('Failed:\%1', GetLastErrorText());
                    if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeaderStaging."Document No.") then
                        Error('Purchase Order not found for Document No. %1', PurchaseHeaderStaging."Document No.");

                    Page.Run(Page::"Purchase Order", PurchaseHeader);
                end;
            }
        }
    }

    var
        FleetrockSetup: Record "EE Fleetrock Setup";
        FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
        ShowPurchDocNo: Boolean;

    trigger OnOpenPage()
    begin
        FleetrockSetup.Get();
        ShowPurchDocNo := FleetrockSetup."Import Repairs as Purchases";
    end;


}