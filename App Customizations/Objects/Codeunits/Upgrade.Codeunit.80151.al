codeunit 80151 "EEC Upgrade"
{
    Subtype = Upgrade;

    Permissions = tabledata "Posted Gen. Journal Line" = RD;

    trigger OnUpgradePerCompany()
    var
        PostGenJnlLine: Record "Posted Gen. Journal Line";
    begin
        // if CompanyName = 'Test - CTS' then begin
        //     PostGenJnlLine.SetFilter("Line No.", '1|2|3|4|5|7|10|13|14|15|16|17|18|19|20|21|22|23');
        //     PostGenJnlLine.DeleteAll(false);
        // end;
        // if CompanyName = 'Test - Eagle Eye Logistics' then begin
        //     PostGenJnlLine.SetFilter("G/L Register No.", '>%1', 49);
        //     PostGenJnlLine.DeleteAll(false);
        // end;
    end;
}