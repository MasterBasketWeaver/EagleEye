enum 80001 "EE Purch. Order Status"
{
    Caption = 'Purch. Order Status';
    Extensible = true;

    value(0; "Draft") { }
    value(1; "Waiting") { }
    value(2; "Open") { }
    value(3; "Received") { }
    value(4; "Closed") { }
    value(5; "Deleted") { }
}