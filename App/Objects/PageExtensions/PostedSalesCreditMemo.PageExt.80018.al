pageextension 80018 "EE Posted Sales Credit Memo" extends "Posted Sales Credit Memo"
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
            action("EE Import Invoices to Cancel")
            {
                ApplicationArea = all;
                Image = ReverseLines;
                Caption = 'Import Invoices to Cancel';
                ToolTip = 'Import invoices from excel to cancel.';

                trigger OnAction()
                var
                    ExcelBuffer: Record "Excel Buffer" temporary;
                    NameBuffer: Record "Name/Value Buffer" temporary;
                    SalesInvHeader: Record "Sales Invoice Header";
                    FileMgt: Codeunit "File Management";
                    TempBlob: Codeunit "Temp Blob";
                    CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
                    FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
                    Window: Dialog;
                    IStream: InStream;
                    DocNos: TextBuilder;
                    ImportedCount, CancelCount, ErrorCount, Skipped : Integer;
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

                    Window.Open('Cancelling...\#1###\#2###');
                    repeat
                        Window.Update(1, StrSubstNo('%1 of %2', ExcelBuffer."Row No." - 1, ImportedCount));
                        Window.Update(2, ExcelBuffer."Cell Value as Text");
                        SalesInvHeader.SetRange("EE Fleetrock ID", ExcelBuffer."Cell Value as Text");
                        SalesInvHeader.SetRange(Cancelled, false);
                        SalesInvHeader.SetFilter(Amount, '<>%1', 0);
                        if SalesInvHeader.FindFirst() then begin
                            Clear(CorrectPostedSalesInvoice);
                            ClearLastError();
                            Commit();
                            if not CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader) then begin
                                DocNos.AppendLine(StrSubstNo('%1: %2', SalesInvHeader."No.", GetLastErrorText()));
                                ErrorCount += 1;
                            end else
                                CancelCount += 1;
                        end else begin
                            DocNos.AppendLine(StrSubstNo('Skipped: %1', ExcelBuffer."Cell Value as Text"));
                            Skipped += 1;
                        end;
                    until ExcelBuffer.Next() = 0;
                    Window.Close();

                    Message('Cancelled: %1 of %2\failed: %3, skipped: %4\\%5', CancelCount, ImportedCount, ErrorCount, Skipped, DocNos.ToText());
                end;
            }
        }
    }
}