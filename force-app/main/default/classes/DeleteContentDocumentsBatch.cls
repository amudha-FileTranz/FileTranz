/*
 * Purpose : To delete uploaded documents from Salesforce
 * Author  : Anandhakumar Thangasamy
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class DeleteContentDocumentsBatch implements Database.Batchable<sObject>, Database.Stateful {
    Set<Id> setContentDocumentId = new Set<Id>();
    Integer intNumOfErrors = 0;
    String strFailedIds = '';
    
    global DeleteContentDocumentsBatch(Set<Id> setContentDocumentId) {
        this.setContentDocumentId = setContentDocumentId;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (!Schema.sObjectType.ContentDocument.isAccessible()) {
            return null;
        } else {
            String strQuery = 'SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentId';
            return Database.getQueryLocator(strQuery);
        }
    }
    global void execute(Database.BatchableContext bc, List<ContentDocument> lstDocument) {
        if (!lstDocument.isEmpty() && Schema.sObjectType.ContentDocument.isDeletable()){
            List<Database.DeleteResult> lstDeleteResult = Database.delete(lstDocument, false, AccessLevel.USER_MODE);
            for (Database.DeleteResult objDeleteResult : lstDeleteResult) {
                if (!objDeleteResult.isSuccess()) {
                    intNumOfErrors++;
                    strFailedIds += '\'' +(objDeleteResult.getId());
                }
            }
        }
    }
    global void finish(Database.BatchableContext bc) {
        String strFailedRecordIds = '';
        if(strFailedIds != '' || Test.isRunningTest()){
            strFailedRecordIds += '  Record Ids that are captured while throwing an exception:   <br/>' + strFailedIds.removeEnd(', ');
            Set<Id> setRecipientIds = new Set<Id>{ UserInfo.getUserId() };
            if(Schema.SObjectType.Exception_Error__c.isAccessible() && Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.StackTraceString__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Exception_Message__c.isCreateable()
            && Schema.SObjectType.Exception_Error__c.fields.BatchJobId__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Record_Id__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Status_Code__c.isCreateable()){
                ErrorLogger.LogBatchErrorsWrapper objLogBatchErrorsWrapper = new ErrorLogger.LogBatchErrorsWrapper();
                objLogBatchErrorsWrapper.apexJobId = bc.getJobId();
                objLogBatchErrorsWrapper.strBatchClassName = 'DeleteContentDocumentsBatch';
                objLogBatchErrorsWrapper.setUserIds = setRecipientIds;
                objLogBatchErrorsWrapper.strFailures = strFailedRecordIds;
                objLogBatchErrorsWrapper.intNumOfErrors = intNumOfErrors;
                ErrorLogger.logBatchErrors(objLogBatchErrorsWrapper);
            }
        }
    }
}