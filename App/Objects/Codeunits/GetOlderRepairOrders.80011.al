codeunit 80011 "EE Get Older Repair Orders"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EE Fleetrock Setup" = r,
    tabledata "EE Import/Export Entry" = r;



    trigger OnRun()
    var
        FleetrockSetup: Record "EE Fleetrock Setup";
        GetRepairOrders: Codeunit "EE Get Repair Orders";
        StartDateTime: DateTime;
    begin
        FleetrockSetup.Get();
        FleetrockSetup.TestField("Check Repair Order DateFormula");

        StartDateTime := CreateDateTime(CalcDate(FleetrockSetup."Check Repair Order DateFormula", Today()), 0T);
        Rec."Parameter String" := 'invoiced';

        GetRepairOrders.SetStartDateTime(StartDateTime);
        GetRepairOrders.Run(Rec);
    end;

}