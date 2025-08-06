pageextension 80008 "EE Posted Purchase Invoices" extends "Posted Purchase Invoices"
{
    layout
    {
        addafter("No.")
        {
            field("EE Fleetrock ID"; Rec."EE Fleetrock ID")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("EE Import Invoices to Update")
            {
                ApplicationArea = all;
                Image = ReverseLines;
                Caption = 'Import Invoices to Update';
                ToolTip = 'Import invoices from excel to update remit-to information.';

                trigger OnAction()
                var
                    ExcelBuffer: Record "Excel Buffer" temporary;
                    NameBuffer: Record "Name/Value Buffer" temporary;
                    PurchInvHeader: Record "Purch. Inv. Header";
                    FileMgt: Codeunit "File Management";
                    TempBlob: Codeunit "Temp Blob";
                    CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                    Window: Dialog;
                    IStream: InStream;
                    DocNos: TextBuilder;
                    ImportedCount, UpdatedCount, ErrorCount, Skipped : Integer;
                begin
                    if FileMgt.BLOBImportWithFilter(TempBlob, 'Excel Import', 'ItemExcelImport', 'Excel files (*.xlsx)|*.xlsx', 'xlsx') = '' then
                        exit;
                    TempBlob.CreateInStream(IStream);
                    if not ExcelBuffer.GetSheetsNameListFromStream(IStream, NameBuffer) or not NameBuffer.FindFirst() then
                        exit;

                    ExcelBuffer.OpenBookStream(IStream, NameBuffer.Value);
                    ExcelBuffer.ReadSheet();
                    ExcelBuffer.SetFilter("Row No.", '>%1', 1);
                    ExcelBuffer.SetRange("Column No.", 1);
                    ExcelBuffer.SetFilter("Cell Value as Text", '<>%1', '');
                    if not ExcelBuffer.FindSet() then
                        exit;
                    ImportedCount := ExcelBuffer.Count();

                    Window.Open('Reversing...\#1###');
                    repeat
                        Window.Update(1, StrSubstNo('%1 of %2', ExcelBuffer."Row No." - 1, ImportedCount));
                        PurchInvHeader.SetRange("EE Fleetrock ID", ExcelBuffer."Cell Value as Text");
                        PurchInvHeader.SetRange(Cancelled, false);
                        PurchInvHeader.SetFilter(Amount, '<>%1', 0);
                        if PurchInvHeader.FindFirst() then begin
                            Clear(CorrectPostedPurchInvoice);
                            ClearLastError();
                            Commit();
                            if not CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader) then begin
                                DocNos.AppendLine(StrSubstNo('%1: %2', PurchInvHeader."No.", GetLastErrorText()));
                                ErrorCount += 1;
                            end else begin
                                Clear(FleetrockMgt);
                                FleetrockMgt.GetAndImportRepairOrder(PurchInvHeader."EE Fleetrock ID", false);
                                UpdatedCount += 1;
                            end;
                        end else begin
                            DocNos.AppendLine(StrSubstNo('Skipped: %1', ExcelBuffer."Cell Value as Text"));
                            Skipped += 1;
                        end;
                    until ExcelBuffer.Next() = 0;
                    Window.Close();

                    Message('Reversed: %1, failed: %2, skipped: %3\\%4', UpdatedCount, ErrorCount, Skipped, DocNos.ToText());
                end;
            }
        }
        addlast(Promoted)
        {
            actionref("EE Import Invoices to Update Promoted"; "EE Import Invoices to Update") { }
        }
    }
}