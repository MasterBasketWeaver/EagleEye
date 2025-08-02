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

    var
        SkipVendorUpdate: Boolean;
}