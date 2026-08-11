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


    procedure GetAllowNegativePostingAmount(): Boolean
    begin
        exit(AllowNegativePostingAmount);
    end;

    procedure SetAllowNegativePostingAmount(NewValue: Boolean)
    begin
        AllowNegativePostingAmount := NewValue;
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
        SkipVendorUpdate, AllowNegativePostingAmount : Boolean;
}