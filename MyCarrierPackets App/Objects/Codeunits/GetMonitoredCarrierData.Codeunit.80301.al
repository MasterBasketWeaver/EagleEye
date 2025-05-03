codeunit 80301 "EEMCP Get Monitored Data"
{
    trigger OnRun()
    var
        MCPMgt: Codeunit "EEMCP My Carrier Packets Mgt.";
    begin
        MCPMgt.GetMonitoredCarrierData();
    end;
}