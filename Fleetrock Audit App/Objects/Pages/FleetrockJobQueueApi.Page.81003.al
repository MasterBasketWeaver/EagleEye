page 81003 "EE Fleetrock JobQueue API"
{
    PageType = API;
    APIPublisher = 'bryanaBcDev';
    APIGroup = 'fleetrockAudit';
    APIVersion = 'v1.0';
    EntityName = 'fleetrockJobQueueEntry';
    EntitySetName = 'fleetrockJobQueueEntries';
    SourceTable = "Job Queue Entry";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(systemId; Rec.SystemId) { Editable = false; }
                field(id; Rec.ID) { Editable = false; }
                field(objectTypeToRun; Rec."Object Type to Run") { }
                field(objectIdToRun; Rec."Object ID to Run") { }
                field(description; Rec.Description) { }
                field(status; Rec.Status) { }
                field(recurringJob; Rec."Recurring Job") { }
                field(numberOfMinutesBetweenRuns; Rec."No. of Minutes between Runs") { }
                field(startingTime; Rec."Starting Time") { }
                field(endingTime; Rec."Ending Time") { }
                field(runOnMonday; Rec."Run on Mondays") { }
                field(runOnTuesday; Rec."Run on Tuesdays") { }
                field(runOnWednesday; Rec."Run on Wednesdays") { }
                field(runOnThursday; Rec."Run on Thursdays") { }
                field(runOnFriday; Rec."Run on Fridays") { }
                field(runOnSaturday; Rec."Run on Saturdays") { }
                field(runOnSunday; Rec."Run on Sundays") { }
                field(earliestStartDateTime; Rec."Earliest Start Date/Time") { }
            }
        }
    }
}
