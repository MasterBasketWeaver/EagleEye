codeunit 80008 "EE Single Instance"
{
    SingleInstance = true;

    procedure GetSkipVendorUpdate(): Boolean
    begin
        exit(SkipVendorUpdate);
    end;

    procedure SetSkipVendorUpdate(NewValue: Boolean)
    begin
        SkipVendorUpdate := NewValue;
    end;


    procedure GetAllowNegativePurchAmount(): Boolean
    begin
        exit(AllowNegativePurchAmount);
    end;

    procedure SetAllowNegativePurchAmount(NewValue: Boolean)
    begin
        AllowNegativePurchAmount := NewValue;
    end;

    var
        SkipVendorUpdate, AllowNegativePurchAmount : Boolean;
}