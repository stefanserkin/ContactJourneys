public with sharing class JourneyBatchEnrollments implements Database.Batchable<SObject> {

    public static final String JOB_NAME = 'Journey Enrollments Batch';
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Journey_Batch_Setting__mdt batchSetting = Journey_Batch_Setting__mdt.getInstance('Enrollment');
        System.debug(':::: batchSetting --> ' + batchSetting);
        return Database.getQueryLocator(batchSetting.Query__c);
    }

    public void execute(Database.BatchableContext bc, List<Contact> contacts) {
        System.debug(':::: running batch for contacts --> ' + contacts);
        Set<Id> contactIds = new Map<Id, Contact>(contacts).keySet();
        Map<String, Object> inputs = new Map<String, Object> { 'contactIds' => contactIds };
        System.debug(':::: ready to call flow with inputs --> ' + inputs);
        Flow.Interview enrollmentsFlow = new Flow.Interview.JourneyEnrollmentsAutolaunched(inputs);
        enrollmentsFlow.start();
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob apexJob = [
            SELECT Id, 
                   Status, 
                   NumberOfErrors, 
                   JobItemsProcessed, 
                   TotalJobItems, 
                   CreatedBy.Email
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
    }

}