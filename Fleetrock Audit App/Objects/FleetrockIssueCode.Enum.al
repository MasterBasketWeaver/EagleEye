enum 81001 "EE Fleetrock Issue Code"
{
    Extensible = true;
    Caption = 'Fleetrock Issue Code';

    value(0; H1)
    {
        Caption = 'H1 - Header vs lines';
    }
    value(1; H2)
    {
        Caption = 'H2 - Tax total vs line tax';
    }
    value(2; L1)
    {
        Caption = 'L1 - Line subtotal vs qty x price';
    }
}
