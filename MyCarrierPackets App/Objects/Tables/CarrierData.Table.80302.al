table 80302 "EEMCP Carrier Data"
{
    Caption = 'Carrier Data';
    DataClassification = CustomerContent;
    DrillDownPageId = "EEMCP Carrier Data";
    LookupPageId = "EEMCP Carrier Data";

    fields
    {
        field(1; "DOT No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "EEMCP Carrier"."DOT No.";
        }
        field(2; "Docket No."; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "LegalName"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "DBAName"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6; "Address1"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7; "Address2"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8; "City"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(9; "Zipcode"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "State"; Text[10])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; "Country"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "CellPhone"; Text[30])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; "Phone"; Text[30])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; "Fax"; Text[30])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(15; "FreePhone"; Text[30])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; "EmergencyPhone"; Text[30])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(17; "Email"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(18; "FraudIdentityTheftStatus"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "SCAC"; Text[10])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(21; "MailingAddress1"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(22; "MailingAddress2"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; "MailingCity"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; "MailingState"; Text[10])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(25; "MailingZipcode"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; "MailingCountry"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(27; "BankRoutingNumber"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(28; "BankAccountNumber"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(29; "BankAccountName"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(30; "BankName"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(31; "BankAddress"; Text[200])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(32; "BankPhone"; Text[30])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(33; "BankFax"; Text[30])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(35; "RemitAddress1"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(36; "RemitAddress2"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(37; "RemitCity"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(38; "RemitZipCode"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(39; "BankAccountType"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(40; "RemitState"; Text[10])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(41; "RemitCountry"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(42; "RemitEmail"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(43; "Require1099"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(44; "EpayManagerID"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(45; "RemitCurrency"; Text[10])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(46; "PayAdvanceOptionID"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(47; "PayAdvanceOptionType"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(48; "CarrierRemitEmail"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(49; "CarrierRemitAddress1"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50; "CarrierRemitAddress2"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51; "CarrierRemitCity"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(52; "CarrierRemitCountry"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(53; "CarrierRemitStateProvince"; Text[10])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(54; "CarrierRemitZipCode"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(55; "PaymentTermsDays"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(56; "CarrierPaymentType"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(57; "FactoringCompanyID"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(58; "FactoringCompanyName"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(59; "FactoringRemitEmail"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(60; "FactoringRemitAddress"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(61; "FactoringRemitAddress2"; Text[100])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(62; "FactoringRemitCity"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(63; "FactoringRemitCountry"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(64; "FactoringRemitStateProvince"; Text[10])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(65; "FactoringRemitZipcode"; Text[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(66; "FactoringPhone"; Text[30])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "DOT No.")
        {
            Clustered = true;
        }
        key(K2; "Docket No.") { }
    }
}