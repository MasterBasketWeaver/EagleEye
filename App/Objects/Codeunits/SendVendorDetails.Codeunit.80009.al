codeunit 80009 "EE Send Vendor Details"
{

    trigger OnRun()
    var
        Vendor: Record Vendor;
        FleetrockMgt: Codeunit "EE Fleetrock Mgt.";
    begin
        Vendor.SetFilter("EE Export Event Type", '%1|%2', Enum::"EE Event Type"::Created, Enum::"EE Event Type"::Updated);
        if Vendor.FindSet(true) then
            repeat
                if FleetrockMgt.SendVendorDetails(Vendor, Vendor."EE Export Event Type") then begin
                    Vendor."EE Export Event Type" := Enum::"EE Event Type"::" ";
                    Vendor.Modify(false);
                end;
            until Vendor.Next() = 0;
    end;
}