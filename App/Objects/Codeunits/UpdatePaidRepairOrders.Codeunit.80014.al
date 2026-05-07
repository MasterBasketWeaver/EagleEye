codeunit 80014 "EE Update Paid Repair Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "Sales Invoice Header" = RIMD;

    trigger OnRun()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentDateTime: DateTime;
    begin
        SalesInvHeader.SetLoadFields();
        SalesInvHeader.SetFilter("EE Fleetrock ID", '<>%1', '');
        SalesInvHeader.SetRange("EE Sent Payment", false);
        SalesInvHeader.SetRange("EE No Repair Order On Payment", false);
        SalesInvHeader.SetRange(Closed, true);
        SalesInvHeader.SetRange("Remaining Amount", 0);
        SalesInvHeader.SetRange(Cancelled, false);
        if not SalesInvHeader.FindSet() then
            exit;

        CustLedgerEntry.SetLoadFields("Closed at Date");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetFilter("Closed at Date", '<>%1&<>%2', 0D, Today());
        repeat
            CustLedgerEntry.SetRange("Document No.", SalesInvHeader."No.");
            if CustLedgerEntry.FindFirst() then
                PaymentDateTime := CreateDateTime(CustLedgerEntry."Closed at Date", Time())
            else
                PaymentDateTime := CurrentDateTime();
            if not FleetrockMgt.DoesRepairOrderExist(SalesInvHeader."EE Fleetrock ID", false) and not FleetrockMgt.DoesRepairOrderExist(SalesInvHeader."EE Fleetrock ID", true) then begin
                SalesInvHeader.Validate("EE Sent Payment", true);
                SalesInvHeader.Validate("EE No Repair Order On Payment", true);
                SalesInvHeader.Modify(true);
            end else
                FleetrockMgt.UpdatePaidRepairOrder(SalesInvHeader."EE Fleetrock ID", PaymentDateTime, SalesInvHeader);
            Commit();
        until SalesInvHeader.Next() = 0;
    end;

    var
        FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
}
