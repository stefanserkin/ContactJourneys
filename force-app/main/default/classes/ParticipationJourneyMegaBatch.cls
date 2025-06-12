public with sharing class ParticipationJourneyMegaBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final String JOB_NAME = 'Participation Journey Mega Batch';

    private static List<Journey_Batch_Setting__mdt> batchSettings;
    private static Integer batchSettingIndex = 0;
    private static Journey_Batch_Setting__mdt currentBatchSetting;

    public ParticipationJourneyMegaBatch() {
        if (batchSettings == null) {
            batchSettings = [
                SELECT Id, Query__c, Flow_Api_Name__c, Batch_Size__c
                  FROM Journey_Batch_Setting__mdt
                 WHERE Active__c = true
                 ORDER BY Sequence_Number__c ASC NULLS LAST
            ];
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        currentBatchSetting = batchSettings[batchSettingIndex];
        return Database.getQueryLocator(currentBatchSetting.Query__c);
    }

    public void execute(Database.BatchableContext bc, List<SObject> sobjs) {
        Set<Id> recordIds = new Map<Id, SObject>(sobjs).keySet();
        Map<String, Object> inputs = new Map<String, Object> { 'recordIds' => recordIds };
        Flow.Interview journeyFlow = Flow.Interview.createInterview(currentBatchSetting.Flow_Api_Name__c, inputs);
        journeyFlow.start();
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob apexJob = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
              FROM AsyncApexJob 
             WHERE Id = :bc.getJobId()
        ];
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        email.setToAddresses(toAddress);
        email.setSubject(apexJob.Status + ': ' + JOB_NAME);
        email.setPlainTextBody('The ' + JOB_NAME + ' ran and processed ' + 
            apexJob.TotalJobItems + ' batches with ' + apexJob.NumberOfErrors + 
            ' failures. Job Id: ' + apexJob.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        if (!batchSettings.isEmpty() && batchSettingIndex < batchSettings.size() - 1) {
            batchSettingIndex++;

            ParticipationJourneyMegaBatch pjmb = new ParticipationJourneyMegaBatch();
            Integer batchSize = Integer.valueOf( batchSettings[batchSettingIndex].Batch_Size__c );
            Database.executeBatch(pjmb, batchSize);
        }
    }

}