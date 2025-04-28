permissionset 80300 "EEMCP Permissions"
{
    Caption = 'My Carrier Packets Permissions';
    Assignable = true;
    Permissions = table "EEMCP MyCarrierPackets Setup" = x,
    tabledata "EEMCP MyCarrierPackets Setup" = RIMD,
    page "EEMCP My Carrier Packets Setup" = x,
    codeunit "EEMCP My Carrier Packets Mgt." = x;
}