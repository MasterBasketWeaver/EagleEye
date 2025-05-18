permissionset 80300 "EEMCP Permissions"
{
    Caption = 'My Carrier Packets Permissions';
    Assignable = true;
    Permissions = table "EEMCP MyCarrierPackets Setup" = x,
    table "EEMCP Carrier" = x,
    table "EEMCP Carrier Data" = x,
    tabledata "EEMCP MyCarrierPackets Setup" = RIMD,
    tabledata "EEMCP Carrier" = RIMD,
    tabledata "EEMCP Carrier Data" = RIMD,
    page "EEMCP My Carrier Packets Setup" = x,
    page "EEMCP Carrier Data" = x,
    page "EEMCP Carriers" = x,
    codeunit "EEMCP My Carrier Packets Mgt." = x,
    codeunit "EEMCP Get Monitored Data" = x,
    codeunit "EE REST API Mgt." = x;
}