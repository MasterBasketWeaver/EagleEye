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


    procedure ClearAppliedSalesInvHeaderNos()
    begin
        Clear(AppliedSalesInvHeaderNos);
    end;

    procedure AddAppliedSalesInvHeaderNo(SalesInvHeaderNo: Code[20]; DateValue: Date)
    begin
        if not AppliedSalesInvHeaderNos.ContainsKey(SalesInvHeaderNo) then
            AppliedSalesInvHeaderNos.Add(SalesInvHeaderNo, DateValue);
    end;

    procedure GetAppliedSalesInvHeaderNos(): Dictionary of [Code[20], Date];
    begin
        exit(AppliedSalesInvHeaderNos);
    end;

    var
        AppliedSalesInvHeaderNos: Dictionary of [Code[20], Date];
        SkipVendorUpdate, AllowNegativePurchAmount : Boolean;
}