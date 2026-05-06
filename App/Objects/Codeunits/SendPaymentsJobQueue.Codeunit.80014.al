codeunit 80014 "EE Send Payments Job Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentDateTime: DateTime;
    begin
        SalesInvHeader.SetLoadFields();
        SalesInvHeader.SetFilter("EE Fleetrock ID", '<>%1', '');
        SalesInvHeader.SetRange("EE Sent Payment", false);
        SalesInvHeader.SetRange(Closed, false);
        SalesInvHeader.SetRange("Remaining Amount", 0);
        if not SalesInvHeader.FindSet() then
            exit;

        CustLedgerEntry.SetLoadFields("Closed at Date");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        repeat
            CustLedgerEntry.SetRange("Document No.", SalesInvHeader."No.");
            if CustLedgerEntry.FindFirst() then begin
                if CustLedgerEntry."Closed at Date" = Today() then
                    PaymentDateTime := CurrentDateTime()
                else
                    PaymentDateTime := CreateDateTime(CustLedgerEntry."Closed at Date", Time());
            end else
                PaymentDateTime := CurrentDateTime();
            FleetrockMgt.UpdatePaidRepairOrder(SalesInvHeader."EE Fleetrock ID", PaymentDateTime, SalesInvHeader);
        until SalesInvHeader.Next() = 0;
    end;

    var
        FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
}
