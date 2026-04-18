page 81000 "EE Fleetrock Audit Issues"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "EE Fleetrock Audit Issue";
    Caption = 'Incorrect Fleetrock Order Amounts';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;
    RefreshOnActivate = true;
    SourceTableView = sorting("Order Kind", "Order ID", "Issue Code");

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Order Kind"; Rec."Order Kind")
                {
                    ApplicationArea = All;
                    Caption = 'Document Type';
                    ToolTip = 'Specifies whether this issue is on a Purchase Order or a Repair Order.';
                }
                field("Order ID"; Rec."Order ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Fleetrock order identifier.';
                }
                field("Issue Code"; Rec."Issue Code")
                {
                    ApplicationArea = All;
                    Caption = 'Issue Type';
                    ToolTip = 'Categorizes the mismatch: header vs lines, tax total vs per-line tax, or line subtotal vs quantity x price.';
                }
                field("Line Ref"; Rec."Line Ref")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line or task reference that caused the mismatch, if any.';
                }
                field("Part Number"; Rec."Part Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Fleetrock part number on the offending line.';
                }
                field("Part Description"; Rec."Part Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the part description or complaint text for the offending line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity (or hours) on the offending line.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit price (or hourly rate) on the offending line.';
                }
                field("Expected Amount"; Rec."Expected Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount the audit calculated.';
                }
                field("Actual Amount"; Rec."Actual Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount reported by Fleetrock.';
                }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = All;
                    StyleExpr = DifferenceStyle;
                    ToolTip = 'Specifies Actual minus Expected. Differences of $1.00 or more are highlighted in red.';
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    Width = 120;
                    ToolTip = 'Human-readable explanation of the mismatch.';
                }
                field("Refreshed At"; Rec."Refreshed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this issue was last loaded from Fleetrock.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Reloads Purchase Orders and Repair Orders from Fleetrock and rebuilds the list of orders with incorrect amounts.';

                trigger OnAction()
                var
                    AuditMgt: Codeunit "EE Fleetrock Audit Mgt";
                begin
                    AuditMgt.RefreshAudit();
                    CurrPage.Update(false);
                end;
            }
            action(ClearList)
            {
                ApplicationArea = All;
                Caption = 'Clear';
                Image = ClearLog;
                ToolTip = 'Removes all currently recorded audit issues without fetching from Fleetrock.';

                trigger OnAction()
                var
                    AuditIssue: Record "EE Fleetrock Audit Issue";
                begin
                    AuditIssue.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
            action(ScheduleHourly)
            {
                ApplicationArea = All;
                Caption = 'Schedule Hourly';
                Image = Timesheet;
                ToolTip = 'Creates or replaces a recurring Job Queue Entry that runs this audit every 60 minutes.';

                trigger OnAction()
                var
                    AuditMgt: Codeunit "EE Fleetrock Audit Mgt";
                begin
                    AuditMgt.ScheduleHourlyAudit();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Refresh_Promoted; Refresh) { }
                actionref(Clear_Promoted; ClearList) { }
                actionref(Schedule_Promoted; ScheduleHourly) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Abs(Rec.Difference) >= 1.0 then
            DifferenceStyle := 'Unfavorable'
        else
            DifferenceStyle := 'Standard';
    end;

    var
        DifferenceStyle: Text;
}
