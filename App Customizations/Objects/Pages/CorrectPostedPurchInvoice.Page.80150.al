page 80150 "EE Correct P. Purch. Invoice"
{
    PageType = API;
    APIPublisher = 'BryanABCDev';
    APIGroup = 'Alvys';
    APIVersion = 'v1.0';
    EntitySetName = 'CorrectPostedPurchInvoices';
    EntityName = 'CorrectPostedPurchInvoice';
    Editable = false;
    SourceTable = "Purch. Inv. Header";
    SourceTableTemporary = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            field(systemId; Rec.SystemId)
            {
                ApplicationArea = all;
            }
            field(invoiceNo; Rec."No.")
            {
                ApplicationArea = all;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(Rec."No.");
        if PurchInvHeader.Cancelled then
            Error('Purchase Invoice %1 has already been updated or cancelled.', Rec."No.");
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeader);
    end;

    var
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";

}