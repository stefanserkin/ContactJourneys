public class ParticipationJourneyScheduler implements Schedulable {

    private static final String JOB_NAME = 'Participation Journey Batch - Enrollment';

    public static String run(String cronExpr) {
        return System.schedule(JOB_NAME, cronExpr, new ParticipationJourneyScheduler());
    }

    public void execute(SchedulableContext sc) {
        ParticipationJourneyBatch pjb = new ParticipationJourneyBatch('Enrollment');
        Database.executeBatch(pjb, 50);
    }

}