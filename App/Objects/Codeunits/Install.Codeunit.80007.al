codeunit 80007 "EE Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        Upgrade.UpdateData();
    end;

    var
        Upgrade: Codeunit "EE Upgrade";
}