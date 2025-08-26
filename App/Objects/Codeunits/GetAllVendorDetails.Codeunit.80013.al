codeunit 80013 "EE Get All Vendor Details"
{
    Permissions = tabledata Vendor = RIM;

    trigger OnRun()
    var
        Vendor: Record Vendor;
        FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
        SingleInstance: Codeunit "EE Single Instance";
    begin
        Vendor.SetRange("EE Source Type", Vendor."EE Source Type"::Fleetrock);
        Vendor.SetFilter("EE Source No.", '<>%1', '');
        if not Vendor.FindSet(true) then
            exit;
        SingleInstance.SetSkipVendorUpdate(true);
        repeat
            if FleetrockMgt.UpdateVendor(Vendor, Vendor."EE Source No.", false) then
                Vendor.Modify(true);
        until Vendor.Next() = 0;
        SingleInstance.SetSkipVendorUpdate(false);
    end;
}