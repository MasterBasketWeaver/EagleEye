page 80302 "EEMCP Carrier Data"
{
    SourceTable = "EEMCP Carrier Data";
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    AnalysisModeEnabled = false;
    LinksAllowed = false;
    Caption = 'Carrier Data';

    layout
    {
        area(Content)
        {
            repeater(Line)
            {
                field("DOT No."; Rec."DOT No.")
                {
                    ApplicationArea = all;
                }
                field("Docket No."; Rec."Docket No.")
                {
                    ApplicationArea = all;
                }
                field("LegalName"; Rec."LegalName")
                {
                    ApplicationArea = all;
                }
                field("DBAName"; Rec."DBAName")
                {
                    ApplicationArea = all;
                }
                field("Address1"; Rec."Address1")
                {
                    ApplicationArea = all;
                }
                field("Address2"; Rec."Address2")
                {
                    ApplicationArea = all;
                }
                field("City"; Rec."City")
                {
                    ApplicationArea = all;
                }
                field("Zipcode"; Rec."Zipcode")
                {
                    ApplicationArea = all;
                }
                field("State"; Rec."State")
                {
                    ApplicationArea = all;
                }
                field("Country"; Rec."Country")
                {
                    ApplicationArea = all;
                }
                field("CellPhone"; Rec."CellPhone")
                {
                    ApplicationArea = all;
                }
                field("Phone"; Rec."Phone")
                {
                    ApplicationArea = all;
                }
                field("Fax"; Rec."Fax")
                {
                    ApplicationArea = all;
                }
                field("FreePhone"; Rec."FreePhone")
                {
                    ApplicationArea = all;
                }
                field("EmergencyPhone"; Rec."EmergencyPhone")
                {
                    ApplicationArea = all;
                }
                field("Email"; Rec."Email")
                {
                    ApplicationArea = all;
                }
                field("FraudIdentityTheftStatus"; Rec."FraudIdentityTheftStatus")
                {
                    ApplicationArea = all;
                }
                field("SCAC"; Rec."SCAC")
                {
                    ApplicationArea = all;
                }
                field("MailingAddress1"; Rec."MailingAddress1")
                {
                    ApplicationArea = all;
                }
                field("MailingAddress2"; Rec."MailingAddress2")
                {
                    ApplicationArea = all;
                }
                field("MailingCity"; Rec."MailingCity")
                {
                    ApplicationArea = all;
                }
                field("MailingState"; Rec."MailingState")
                {
                    ApplicationArea = all;
                }
                field("MailingZipcode"; Rec."MailingZipcode")
                {
                    ApplicationArea = all;
                }
                field("MailingCountry"; Rec."MailingCountry")
                {
                    ApplicationArea = all;
                }
                field("BankRoutingNumber"; Rec."BankRoutingNumber")
                {
                    ApplicationArea = all;
                }
                field("BankAccountNumber"; Rec."BankAccountNumber")
                {
                    ApplicationArea = all;
                }
                field("BankAccountName"; Rec."BankAccountName")
                {
                    ApplicationArea = all;
                }
                field("BankName"; Rec."BankName")
                {
                    ApplicationArea = all;
                }
                field("BankAddress"; Rec."BankAddress")
                {
                    ApplicationArea = all;
                }
                field("BankPhone"; Rec."BankPhone")
                {
                    ApplicationArea = all;
                }
                field("BankFax"; Rec."BankFax")
                {
                    ApplicationArea = all;
                }
                field("RemitAddress1"; Rec."RemitAddress1")
                {
                    ApplicationArea = all;
                }
                field("RemitAddress2"; Rec."RemitAddress2")
                {
                    ApplicationArea = all;
                }
                field("RemitCity"; Rec."RemitCity")
                {
                    ApplicationArea = all;
                }
                field("RemitZipCode"; Rec."RemitZipCode")
                {
                    ApplicationArea = all;
                }
                field("BankAccountType"; Rec."BankAccountType")
                {
                    ApplicationArea = all;
                }
                field("RemitState"; Rec."RemitState")
                {
                    ApplicationArea = all;
                }
                field("RemitCountry"; Rec."RemitCountry")
                {
                    ApplicationArea = all;
                }
                field("RemitEmail"; Rec."RemitEmail")
                {
                    ApplicationArea = all;
                }
                field("Require1099"; Rec."Require1099")
                {
                    ApplicationArea = all;
                }
                field("EpayManagerID"; Rec."EpayManagerID")
                {
                    ApplicationArea = all;
                }
                field("RemitCurrency"; Rec."RemitCurrency")
                {
                    ApplicationArea = all;
                }
                field("PayAdvanceOptionID"; Rec."PayAdvanceOptionID")
                {
                    ApplicationArea = all;
                }
                field("PayAdvanceOptionType"; Rec."PayAdvanceOptionType")
                {
                    ApplicationArea = all;
                }
                // field("CarrierRemitEmail"; Rec."CarrierRemitEmail")
                // {
                //     ApplicationArea = all;
                // }
                // field("CarrierRemitAddress1"; Rec."CarrierRemitAddress1")
                // {
                //     ApplicationArea = all;
                // }
                // field("CarrierRemitAddress2"; Rec."CarrierRemitAddress2")
                // {
                //     ApplicationArea = all;
                // }
                // field("CarrierRemitCity"; Rec."CarrierRemitCity")
                // {
                //     ApplicationArea = all;
                // }
                // field("CarrierRemitCountry"; Rec."CarrierRemitCountry")
                // {
                //     ApplicationArea = all;
                // }
                // field("CarrierRemitStateProvince"; Rec."CarrierRemitStateProvince")
                // {
                //     ApplicationArea = all;
                // }
                // field("CarrierRemitZipCode"; Rec."CarrierRemitZipCode")
                // {
                //     ApplicationArea = all;
                // }
                field("CarrierPaymentType"; Rec."CarrierPaymentType")
                {
                    ApplicationArea = all;
                }
                field("FactoringCompanyID"; Rec."FactoringCompanyID")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("FactoringCompanyName"; Rec."FactoringCompanyName")
                {
                    ApplicationArea = all;
                }
                field("FactoringRemitEmail"; Rec."FactoringRemitEmail")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("FactoringRemitAddress"; Rec."FactoringRemitAddress")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("FactoringRemitAddress2"; Rec."FactoringRemitAddress2")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("FactoringRemitCity"; Rec."FactoringRemitCity")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("FactoringRemitCountry"; Rec."FactoringRemitCountry")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("FactoringRemitStateProvince"; Rec."FactoringRemitStateProvince")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("FactoringRemitZipcode"; Rec."FactoringRemitZipcode")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("FactoringPhone"; Rec."FactoringPhone")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
            }
        }
    }
}