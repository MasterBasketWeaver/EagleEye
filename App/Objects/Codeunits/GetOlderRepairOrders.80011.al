codeunit 80011 "EE Get Older Repair Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Import/Export Entry" = r;



    trigger OnRun()
    var
        FleetrockSetup: Record "EE Fleetrock Setup";
        GetRepairOrders: Codeunit "EE Get Repair Orders";
    begin
        FleetrockSetup.Get();
        FleetrockSetup.TestField("Check Repair Order DateFormula");

        Rec."Parameter String" := 'invoiced';
        GetRepairOrders.SetStartDateTime(CreateDateTime(CalcDate(FleetrockSetup."Check Repair Order DateFormula", Today()), 0T));
        GetRepairOrders.Run(Rec);
    end;

}