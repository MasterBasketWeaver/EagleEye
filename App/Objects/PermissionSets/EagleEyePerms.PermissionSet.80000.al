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
    table "EE Claim Header" = x,
    table "EE Claim Line" = x,
    tabledata "EE Fleetrock Setup" = rimd,
    tabledata "EE Purch. Header Staging" = rimd,
    tabledata "EE Purch. Line Staging" = rimd,
    tabledata "EE Import/Export Entry" = rimd,
    tabledata "EE Sales Header Staging" = rimd,
    tabledata "EE Task Line Staging" = rimd,
    tabledata "EE Part Line Staging" = rimd,
    tabledata "EE Claim Header" = rimd,
    tabledata "EE Claim Line" = rimd;
}