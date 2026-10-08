codeunit 80154 "EE Test Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Codeunit, Codeunit::"EE Test API", 'FleetrockTestAPI', true);
    end;
}
