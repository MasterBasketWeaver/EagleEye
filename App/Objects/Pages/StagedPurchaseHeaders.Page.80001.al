page 80001 "EE Staged Purchased Headers"
{
    ApplicationArea = all;
    SourceTable = "EE Purch. Header Staging";
    UsageCategory = Lists;
    Caption = 'Staged Purchase Headers';
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
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the Document No. of the related Purchase Order that was created from the staging record.';

                    trigger OnDrillDown()
                    var
                        PurchaseHeader: Record "Purchase Header";
                        PurchInvHeader: Record "Purch. Inv. Header";
                    begin
                        if Rec."Document No." <> '' then
                            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."Document No.") then
                                Page.Run(Page::"Purchase Order", PurchaseHeader)
                            else begin
                                PurchInvHeader.SetCurrentKey("Order No.");
                                PurchInvHeader.SetRange("Order No.", Rec."Document No.");
                                if not PurchInvHeader.FindFirst() then begin
                                    PurchInvHeader.Reset();
                                    PurchInvHeader.SetCurrentKey("Pre-Assigned No.");
                                    PurchInvHeader.SetRange("Pre-Assigned No.", Rec."Document No.");
                                    if not PurchInvHeader.FindFirst() then
                                        exit;
                                end;
                                Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
                            end;
                    end;
                }
                field(id; Rec.id)
                {
                    ApplicationArea = All;
                }
                field(Lines; Rec.Lines)
                {
                    ApplicationArea = all;
                }
                field(supplier_name; Rec.supplier_name)
                {
                    ApplicationArea = All;
                }
                field(supplier_custom_id; Rec.supplier_custom_id)
                {
                    ApplicationArea = All;
                }
                field(recipient_name; Rec.recipient_name)
                {
                    ApplicationArea = All;
                }
                field(tag; Rec.tag)
                {
                    ApplicationArea = All;
                }
                field(status; Rec.status)
                {
                    ApplicationArea = All;
                }
                field(date_created; Rec.date_created)
                {
                    ApplicationArea = All;
                }
                field(date_opened; Rec.date_opened)
                {
                    ApplicationArea = All;
                }
                field(date_received; Rec.date_received)
                {
                    ApplicationArea = All;
                }
                field(date_closed; Rec.date_closed)
                {
                    ApplicationArea = All;
                }
                field(Created; Rec.Created)
                {
                    ApplicationArea = all;
                }
                field(Opened; Rec.Opened)
                {
                    ApplicationArea = all;
                }
                field(Received; Rec.Received)
                {
                    ApplicationArea = all;
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = all;
                }
                field(Imported; Rec.SystemCreatedAt)
                {
                    ApplicationArea = all;
                    Caption = 'Imported At';
                }
                field("Imported By"; Rec."Imported By")
                {
                    ApplicationArea = all;
                }
                field(payment_term_days; Rec.payment_term_days)
                {
                    ApplicationArea = All;
                }
                field(invoice_number; Rec.invoice_number)
                {
                    ApplicationArea = All;
                }
                field(subtotal; Rec.subtotal)
                {
                    ApplicationArea = all;
                }
                field(tax_total; Rec.tax_total)
                {
                    ApplicationArea = all;
                }
                field(shipping_total; Rec.shipping_total)
                {
                    ApplicationArea = all;
                }
                field(other_total; Rec.other_total)
                {
                    ApplicationArea = all;
                }
                field(grand_total; Rec.grand_total)
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
                field(Processed; Rec.Processed)
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

                trigger OnAction()
                begin
                    Message(Rec."Error Message");
                end;
            }
        }
    }
}