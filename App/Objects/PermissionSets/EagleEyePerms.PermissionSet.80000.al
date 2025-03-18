permissionset 80000 "EE Eagle Eye Perms."
{
    Caption = 'Eagle Eye Permissions';
    Assignable = true;
    Permissions = table "EE Fleetrock Setup" = x,
    table "EE Purch. Header Staging" = x,
    table "EE Purch. Line Staging" = x,
    table "EE Import/Export Entry" = x,
    table "EE Sales Header Staging" = x,
    table "EE Task Line Staging" = x,
    table "EE Part Line Staging" = x,
    tabledata "EE Fleetrock Setup" = RIMD,
    tabledata "EE Purch. Header Staging" = RIMD,
    tabledata "EE Purch. Line Staging" = RIMD,
    tabledata "EE Import/Export Entry" = RIMD,
    tabledata "EE Sales Header Staging" = RIMD,
    tabledata "EE Task Line Staging" = RIMD,
    tabledata "EE Part Line Staging" = RIMD;
}