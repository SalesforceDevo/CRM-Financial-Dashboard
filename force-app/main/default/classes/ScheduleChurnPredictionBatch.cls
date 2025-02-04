global class ScheduleChurnPredictionBatch implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ChurnPredictionBatch(), 50);
    }
}
