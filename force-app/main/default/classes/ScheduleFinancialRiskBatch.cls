global class ScheduleFinancialRiskBatch implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Execute the existing batch job - financial risk batch
        Database.executeBatch(new FinancialRiskBatch(), 50);
    }
}
