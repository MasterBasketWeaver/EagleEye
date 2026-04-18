enum 81001 "EE Fleetrock Issue Code"
{
    Extensible = true;
    Caption = 'Fleetrock Issue Type';

    value(0; H1)
    {
        Caption = 'Header vs lines';
    }
    value(1; H2)
    {
        Caption = 'Tax total vs line tax';
    }
    value(2; L1)
    {
        Caption = 'Line subtotal vs qty x price';
    }
}
