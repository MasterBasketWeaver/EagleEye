page 80001 "EE Staged Purchased Headers"
{
    ApplicationArea = all;
    SourceTable = "EE Purch. Header Staging";
    UsageCategory = Lists;
    Caption = 'Staged Purchase Headers';
    Editable = false;
    LinksAllowed = false;
    PageType = List;

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
                field(Created; Rec.Created)
                {
                    ApplicationArea = all;
                }
                field(date_opened; Rec.date_opened)
                {
                    ApplicationArea = All;
                }
                field(Opened; Rec.Opened)
                {
                    ApplicationArea = all;
                }
                field(date_received; Rec.date_received)
                {
                    ApplicationArea = All;
                }
                field(Received; Rec.Received)
                {
                    ApplicationArea = all;
                }
                field(date_closed; Rec.date_closed)
                {
                    ApplicationArea = All;
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = all;
                }
                field(Imported; Rec.SystemCreatedAt)
                {
                    ApplicationArea = all;
                }
                field("Imported By"; Rec.SystemCreatedBy)
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
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = all;
                }
                field("Insert Error"; Rec."Insert Error")
                {
                    ApplicationArea = all;
                }
                field("Processed Error"; Rec."Processed Error")
                {
                    ApplicationArea = all;
                }
            }
        }
    }
}