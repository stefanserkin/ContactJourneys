public with sharing class ParticipationJourneyBatch implements Database.Batchable<SObject> {

    private Journey_Batch_Setting__mdt batchSetting;

    public ParticipationJourneyBatch(String batchSettingName) {
        batchSetting = Journey_Batch_Setting__mdt.getInstance(batchSettingName);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(batchSetting.Query__c);
    }

    public void execute(Database.BatchableContext bc, List<SObject> sobjs) {
        Set<Id> recordIds = new Map<Id, SObject>(sobjs).keySet();
        Map<String, Object> inputs = new Map<String, Object> { 'recordIds' => recordIds };
        Flow.Interview journeyFlow = Flow.Interview.createInterview(batchSetting.Flow_API_Name__c, inputs);
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
        email.setSubject(apexJob.Status + ': Participation Journey Batch');
        email.setPlainTextBody('The Participation Journey Batch ran and processed ' + 
            apexJob.TotalJobItems + ' batches with ' + apexJob.NumberOfErrors + 
            ' failures. Job Id: ' + apexJob.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

}