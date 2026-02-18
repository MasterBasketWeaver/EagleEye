pageextension 80005 "EE Posted Sales Invoice" extends "Posted Sales Invoice"
{
    layout
    {
        addlast(General)
        {
            field("EE Fleetrock ID"; Rec."EE Fleetrock ID")
            {
                ApplicationArea = all;

                trigger OnDrillDown()
                var
                    SalesHeaderStaging: Record "EE Sales Header Staging";
                begin
                    SalesHeaderStaging.DrillDown(Rec."EE Fleetrock ID");
                end;
            }
            field("EE Load Number"; Rec."EE Load Number")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("EE Send Payment")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = PaymentJournal;
                Caption = 'Send Payment';
                ToolTip = 'Updated the related Fleetrock invoice as paid.';
                Enabled = Rec."EE Fleetrock ID" <> '';

                trigger OnAction()
                var
                    ImportExportEntry: Record "EE Import/Export Entry";
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                    StartDateTime: DateTime;
                begin
                    Rec.TestField("EE Fleetrock ID");
                    if Rec."EE Sent Payment" then
                        Error('Invoice %1 already sent payment at %2', Rec."No.", Rec."EE Sent Payment DateTime");
                    Rec.CalcFields(Closed, "Remaining Amount");
                    if not Rec.Closed or (Rec."Remaining Amount" > 0) then
                        Error('Invoice %1 is not fully paid.', Rec."No.");
                    StartDateTime := CurrentDateTime();
                    FleetrockMgt.UpdatePaidRepairOrder(Rec."EE Fleetrock ID", CurrentDateTime(), Rec);
                    Rec.Get(Rec."No.");
                    if not Rec."EE Sent Payment" then begin
                        Commit(); //required to perserve import/export entry
                        ImportExportEntry.SetRange("Fleetrock ID", Rec."EE Fleetrock ID");
                        ImportExportEntry.SetRange(Direction, Enum::"EE Direction"::Export);
                        ImportExportEntry.SetRange("Event Type", Enum::"EE Event Type"::Paid);
                        ImportExportEntry.SetRange(Success, false);
                        ImportExportEntry.SetFilter(SystemCreatedAt, '>%1', StartDateTime);
                        ImportExportEntry.SetFilter("Error Message", '<>%1', '');
                        if ImportExportEntry.FindLast() then
                            Error('Failed to send payment:\\%1', ImportExportEntry."Error Message")
                        else
                            Error('Failed to send payment.');
                    end else
                        Message('Payment sent successfully.');
                end;
            }
        }
    }
}