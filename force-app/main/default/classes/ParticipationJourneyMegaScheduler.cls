public with sharing class ParticipationJourneyMegaScheduler implements Schedulable {

    private static final String JOB_NAME = 'Participation Journey Batch - Enrollment';

    public static String run(String cronExpr) {
        return System.schedule(JOB_NAME, cronExpr, new ParticipationJourneyMegaScheduler());
    }

    public void execute(SchedulableContext sc) {
        List<Journey_Batch_Setting__mdt> batchSettings = [
            SELECT Id, Query__c, Flow_Api_Name__c, Batch_Size__c
              FROM Journey_Batch_Setting__mdt
             WHERE Active__c = true
             ORDER BY Sequence_Number__c ASC NULLS LAST
             LIMIT 1
        ];

        if (batchSettings.isEmpty) {
            return;
        }

        ParticipationJourneyMegaBatch pjmb = new ParticipationJourneyMegaBatch();
        Integer batchSize = Integer.valueOf( batchSettings[0].Batch_Size__c );
        Database.executeBatch(pjmb, batchSize);
    }

}