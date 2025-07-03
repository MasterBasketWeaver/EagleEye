codeunit 80012 "EE Get Older Purch. Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Import/Export Entry" = r;



    trigger OnRun()
    var
        FleetrockSetup: Record "EE Fleetrock Setup";
        GetPurchaseOrders: Codeunit "EE Get Purchase Orders";
    begin
        FleetrockSetup.Get();
        FleetrockSetup.TestField("Check Purch. Order DateFormula");

        GetPurchaseOrders.SetStartDateTime(CreateDateTime(CalcDate(FleetrockSetup."Check Purch. Order DateFormula", Today()), 0T));
        GetPurchaseOrders.Run(Rec);
    end;

}