global class ScheduleFinancialRiskBatch implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Execute the existing batch job
        Database.executeBatch(new FinancialRiskBatch(), 50);
    }
}
