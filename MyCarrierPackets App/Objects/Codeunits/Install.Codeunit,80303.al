codeunit 80302 "EEMCP Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Vendor: Record Vendor;
        DataTrans: DataTransfer;
        Blank: Code[20];
    begin
        if CompanyName <> 'CRONUS USA, Inc.' then
            exit;

        DataTrans.SetTables(Database::Vendor, Database::Vendor);
        DataTrans.AddConstantValue(Blank, Vendor.FieldNo("Pay-to Vendor No."));
        DataTrans.CopyFields();
    end;
}