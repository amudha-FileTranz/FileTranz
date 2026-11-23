/*
 * Purpose : Log errors and exceptions to error log object.
 * Author  : Giri
 */
public with sharing class ErrorLogger {
    
    
    private static String escapeHtml(String input) {
        if (input == null) {
            return null;
        }
        return input.replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
    }
    
    public static Boolean logBatchErrors(LogBatchErrorsWrapper objLogBatchErrorsWrapper) {
        Boolean bolErrors = false;
        try {
            // The read is wrapped in a positive isAccessible() check (rather than a negated
            // early-return guard) because Checkmarx's CRUD-violation rule pattern-matches on
            // the SOQL being inside the accessibility check, not merely preceded by one.
            AsyncApexJob apexJob;
            if (Schema.SObjectType.AsyncApexJob.isAccessible()
                && Schema.SObjectType.AsyncApexJob.fields.Status.isAccessible()
                && Schema.SObjectType.AsyncApexJob.fields.TotalJobItems.isAccessible()
                && Schema.SObjectType.AsyncApexJob.fields.JobItemsProcessed.isAccessible()
                && Schema.SObjectType.AsyncApexJob.fields.NumberOfErrors.isAccessible()
                && Schema.SObjectType.AsyncApexJob.fields.ExtendedStatus.isAccessible()) {
                apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, ExtendedStatus, CreatedBy.Id FROM AsyncApexJob WHERE Id = :objLogBatchErrorsWrapper.apexJobId WITH USER_MODE];
            } else {
                return false;
            }
            if (String.isNotBlank(objLogBatchErrorsWrapper.strFailures) && objLogBatchErrorsWrapper.intNumOfErrors > 0) {
                bolErrors = true;
                String strSummary = objLogBatchErrorsWrapper.strBatchClassName + ' completed successfully with failures.';
                String strMessage = 'Please see Record Ids field for more details on the failures.';
                
                List<Exception_Error__c> lstErrorsToInsert = new List<Exception_Error__c>();
                
                if(Schema.SObjectType.Exception_Error__c.isAccessible() && Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.StackTraceString__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Exception_Message__c.isCreateable()
                && Schema.SObjectType.Exception_Error__c.fields.BatchJobId__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Record_Id__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Status_Code__c.isCreateable()){
                    Exception_Error__c objError = new Exception_Error__c();
                    objError.Related_To__c = objLogBatchErrorsWrapper.strBatchClassName;
                    objError.StackTraceString__c = strSummary;
                    objError.Exception_Message__c = strMessage;
                    objError.BatchJobId__c = objLogBatchErrorsWrapper.apexJobId;
                    objError.Record_Id__c = objLogBatchErrorsWrapper.strFailures;
                    objError.Status_Code__c = null;
                    
                    List<Exception_Error__c> lstErrors = new List<Exception_Error__c>{objError};
                    SObjectAccessDecision decider = Security.stripInaccessible(AccessType.CREATABLE, lstErrors);
                    lstErrorsToInsert = (List<Exception_Error__c>)decider.getRecords();
                    
                    if(!lstErrorsToInsert.isEmpty() && Schema.SObjectType.Exception_Error__c.isCreateable()){
                        insert as User lstErrorsToInsert;
                    }
                    // if(Schema.SObjectType.Exception_Error__c.isCreateable()){
                        //     insert as User objError;
                    // }
                }
            } else{
                if (Schema.SObjectType.Exception_Error__c.isAccessible()) {
                    List<Exception_Error__c> lstExceptions = [SELECT Id,Record_Id__c,Related_to__c, Exception_Message__c FROM Exception_Error__c WHERE BatchJobId__c=:objLogBatchErrorsWrapper.apexJobId WITH USER_MODE];
                    if (!lstExceptions.isEmpty()) {
                        bolErrors = true;
                    }
                } else {
                    return false;
                }
            }
            // Send Email
            if (objLogBatchErrorsWrapper.setUserIds != null && !objLogBatchErrorsWrapper.setUserIds.isEmpty()) {
                
                if (!Schema.SObjectType.AsyncApexJob.isAccessible()
                    || !Schema.SObjectType.AsyncApexJob.fields.Status.isAccessible()
                    || !Schema.SObjectType.AsyncApexJob.fields.TotalJobItems.isAccessible()
                    || !Schema.SObjectType.AsyncApexJob.fields.JobItemsProcessed.isAccessible()
                || !Schema.SObjectType.AsyncApexJob.fields.NumberOfErrors.isAccessible()) {
                    return bolErrors;
                }
                String strSafeClassName     = escapeHtml(objLogBatchErrorsWrapper.strBatchClassName);
                String strStatus            = escapeHtml(apexJob.Status);
                String strTotalJobItems     = String.valueOf(apexJob.TotalJobItems);
                String strJobItemsProcessed = String.valueOf(apexJob.JobItemsProcessed);
                String strNumOfErrors       = String.valueOf(objLogBatchErrorsWrapper.intNumOfErrors);
                String strFailures          = objLogBatchErrorsWrapper.strFailures != null ? escapeHtml(objLogBatchErrorsWrapper.strFailures) : 'N/A';
                String strJobId             = String.valueOf(apexJob.Id);
                
                String strSubject = 'Batch ' + strSafeClassName + ' ' + strStatus;
                String strBody =
                    'Batch Class Name : ' + strSafeClassName +
                    '<br /> Status : ' + strStatus +
                    '<br /> Total Job Items : ' + strTotalJobItems +
                    '<br /> Job Items Processed : ' + strJobItemsProcessed +
                    '<br /> Number of Errors : ' + strNumOfErrors;
                if (bolErrors || (String.isNotBlank(strFailures) && objLogBatchErrorsWrapper.intNumOfErrors > 0)) {
                    strSubject += ' with failures';
                    strBody += '<br /><br /> Please check Exceptions/Errors object with the Batch Job Id : ' + strJobId + '<br /><br /> Below are the failure details, <br />' + strFailures;
                }
                if(Schema.SObjectType.User.isAccessible() && Schema.SObjectType.User.fields.Email.isAccessible()){
                    EmailUtility objEmailUtil = new EmailUtility();
                    objEmailUtil.strSubject = strSubject;
                    objEmailUtil.strhtmlBody = strBody;
                    objEmailUtil.setTargetObjectIds = objLogBatchErrorsWrapper.setUserIds;
                    objEmailUtil.sendEmail();
                }
            }
        } catch (Exception exp) {
            System.debug('Error---- '+ exp.getMessage() + exp.getStackTraceString());
        }
        return bolErrors;
    }
    
    public static Exception_Error__c logBatchException(Id batchJobId, String strRelatedTo, Exception objException) {
        
        List<Exception_Error__c> lstErrorsToInsert = new List<Exception_Error__c>();
        if(Schema.SObjectType.Exception_Error__c.isAccessible() && Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.StackTraceString__c.isCreateable()
            && Schema.SObjectType.Exception_Error__c.fields.Exception_Message__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.BatchJobId__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Record_Id__c.isCreateable()
        && Schema.SObjectType.Exception_Error__c.fields.Status_Code__c.isCreateable()){
            
            Exception_Error__c objError = new Exception_Error__c();
            objError.Related_To__c = strRelatedTo;
            objError.StackTraceString__c = objException.getStackTraceString();
            objError.Exception_Message__c = objException.getMessage();
            objError.BatchJobId__c = batchJobId;
            objError.Record_Id__c = null;
            objError.Status_Code__c = objException.getTypeName();
            
            List<Exception_Error__c> lstErrors = new List<Exception_Error__c>{objError};
            SObjectAccessDecision deciderRecords = Security.stripInaccessible(AccessType.CREATABLE, lstErrors);
            lstErrorsToInsert = (List<Exception_Error__c>)deciderRecords.getRecords();
            
            if(!lstErrorsToInsert.isEmpty()){
                insert as User lstErrorsToInsert;
            }
        }
        // if(Schema.SObjectType.Exception_Error__c.isCreateable()){
            //     insert as User objError;
        // }
        return lstErrorsToInsert.isEmpty() ? null : lstErrorsToInsert[0];
    }
    
    public static Exception_Error__c logException(String strRelatedTo, Exception objException) {
        return logBatchException(null, strRelatedTo, objException);
    }
    
    @AuraEnabled
    public static Exception_Error__c logError(String strLogErrorWrapper) {
        System.debug('strLogErrorWrapper: ' + strLogErrorWrapper);
        if (String.isBlank(strLogErrorWrapper)) {
            return null;
        }
        LogErrorWrapper objLogErrorWrapper = (LogErrorWrapper) JSON.deserialize(strLogErrorWrapper, LogErrorWrapper.class);
        
        if (objLogErrorWrapper == null) {
            return null;
        }
        if(!Schema.SObjectType.Exception_Error__c.isCreateable()){
            throw new AuraHandledException('You do not have access to create error logs. Please contact your administrator.');
        }
        
        List<Exception_Error__c> lstErrorsToInsert = new List<Exception_Error__c>();
        
        if(Schema.SObjectType.Exception_Error__c.isAccessible() && Schema.SObjectType.Exception_Error__c.fields.Related_To__c.isCreateable()
            && Schema.SObjectType.Exception_Error__c.fields.StackTraceString__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Exception_Message__c.isCreateable()
        && Schema.SObjectType.Exception_Error__c.fields.BatchJobId__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Record_Id__c.isCreateable() && Schema.SObjectType.Exception_Error__c.fields.Status_Code__c.isCreateable()){
            
            Exception_Error__c objError = new Exception_Error__c();
            objError.Related_To__c = objLogErrorWrapper.relatedTo;
            objError.StackTraceString__c = objLogErrorWrapper.summary;
            objError.Exception_Message__c = objLogErrorWrapper.message;
            objError.BatchJobId__c = objLogErrorWrapper.batchJobId;
            objError.Record_Id__c = objLogErrorWrapper.recordIds;
            objError.Status_Code__c = objLogErrorWrapper.statusCode;
            
            List<Exception_Error__c> lstErrors = new List<Exception_Error__c>{objError};
            SObjectAccessDecision decider = Security.stripInaccessible(AccessType.CREATABLE, lstErrors);
            lstErrorsToInsert = (List<Exception_Error__c>)decider.getRecords();
            
            if(!lstErrorsToInsert.isEmpty()){
                insert as User lstErrorsToInsert;
            }
        }
        return lstErrorsToInsert.isEmpty() ? null : lstErrorsToInsert[0];
    }
    
    public class LogBatchErrorsWrapper {
        @AuraEnabled
        public Id apexJobId { get; set; }
        @AuraEnabled
        public String strBatchClassName { get; set; }
        @AuraEnabled
        public Set<Id> setUserIds { get; set; }
        @AuraEnabled
        public String strFailures { get; set; }
        @AuraEnabled
        public Integer intNumOfErrors { get; set; }
    }
    
    public class LogErrorWrapper {
        @AuraEnabled
        public String relatedTo { get; set; }
        @AuraEnabled
        public String summary { get; set; }
        @AuraEnabled
        public String message { get; set; }
        @AuraEnabled
        public String batchJobId { get; set; }
        @AuraEnabled
        public String recordIds { get; set; }
        @AuraEnabled
        public String statusCode { get; set; }
    }
}