// codeunit 80305 "EEMCP Upgrade"
// {
//     Subtype = Upgrade;

//     trigger OnUpgradePerCompany()
//     begin
//         Install.InstallData();
//     end;

//     var
//         Install: Codeunit "EEMCP Install";
// }