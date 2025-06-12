codeunit 80152 "EEC Install"
{
    Subtype = Install;


    trigger OnInstallAppPerCompany()
    begin
        Upgrade.InstallData();
    end;

    var
        Upgrade: Codeunit "EEC Upgrade";
}