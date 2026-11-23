/*
 * Purpose	: 	Server side controller for jobConfigurations LWC. To schedule/run the batch jobs, fetch batch job/scheduled
 *				jobs details and to abort the running jobs.
 * Author	: 	Anandhakumar Thangasamy
 */
public with sharing class JobConfigurationsController {

    // The Schedulable classes shipped by FileTranz. Used to make sure job enumeration/abort/delete
    // operations only ever touch FileTranz's own scheduled jobs, never another package's or another
    // admin's unrelated scheduled Apex in the org.
    private static Set<String> getFileTranzSchedulerClassNames() {
        return new Set<String>{
            'MigrateFilesBatchScheduler',
            'MigrateAttachmentsBatchScheduler',
            'EmptyRecycleBinBatchScheduler'
        };
    }

    /**
     * To validate the given query before scheduling/running the batch job from jobConfigurations LWC screen.
     * @param strQuery from jobConfigurations LWC
     * @return String - Success/Error message
     */
    //@SuppressWarnings('PMD.ApexSOQLInjection')
    @AuraEnabled
    public static String validateQuery(String strQuery, Boolean bolScheduleApex) {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to run job queries.');
        }
        String result='';
        if(String.isBlank(strQuery)){
            return 'Query cannot be empty';
        }
        String strQueryNormalized = strQuery.trim().toLowerCase();
        if(!strQueryNormalized.toLowerCase().startsWith('select')){
            return 'Only SELECT statement is allowed';
        }
        List<String> lstRestrictedKeywords = new List<String>{'insert', 'update', 'delete', 'upsert', 'merge'};
        for(String strKeyword : lstRestrictedKeywords){
            if(strQueryNormalized.contains(strKeyword)){
                return 'The query contains restricted keyword: ' + strKeyword;
            }
        }
        //String strQuerySanitized = String.escapeSingleQuotes();
        String strQueryLocal = strQuery  + ' WITH USER_MODE LIMIT 1';
        try {
            System.debug('strQueryLocal::'+strQueryLocal);
            list<sObject> lstObjects = Database.query(strQueryLocal);
            if ((lstObjects != null && lstObjects.size() > 0) || (bolScheduleApex && lstObjects.size() == 0)) {
                result=Label.Success;
                return result;
            } else {
                return Label.No_record_found_for_the_provided_filter_Please_try_changing_the_filter_range + '\nQuery: ' + strQuery;
            }
        } catch (Exception exp) {
            ErrorLogger.logException('JobConfigurationsController.validateQuery', exp);
            return exp.getMessage() + '\nQuery: ' + strQuery;
        }
    }
    /**
     * To schedule the selected job from jobConfigurations LWC screen.
     * @param strName,strCRON,strBatchType,strWhere,bolIncludeUserRecords,bolDeleteUploadedRecords,strLastNdays from jobConfigurations LWC
     * @return ToastWrapper - Success/Error toast message to LWC
     */
    @AuraEnabled
    public static ToastWrapper scheduleJob(String strScheduleJobWrapper) {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to schedule jobs.');
        }

        ScheduleJobWrapper objScheduleJobWrapper = (ScheduleJobWrapper) JSON.deserialize(strScheduleJobWrapper, ScheduleJobWrapper.class);

        String strjobId;
        ToastWrapper objToastWrapper = new ToastWrapper();
        try {
            if (objScheduleJobWrapper.strBatchType == 'Migrate Attachments' || objScheduleJobWrapper.strBatchType == 'Migrate Attachments By Object') {
                objScheduleJobWrapper.strWhere = objScheduleJobWrapper.strWhere != null ? objScheduleJobWrapper.strWhere : '';
            } else {
                objScheduleJobWrapper.strWhere = (objScheduleJobWrapper.strWhere != null && objScheduleJobWrapper.strWhere != '') ? 'WHERE ' + objScheduleJobWrapper.strWhere : '';
            }
            MigrateFilesBatchScheduler.MigrateFilesBatchSchedulerWrapper objMigrateFilesBatchSchedulerWrapper = new MigrateFilesBatchScheduler.MigrateFilesBatchSchedulerWrapper();
            objMigrateFilesBatchSchedulerWrapper.strWhere = objScheduleJobWrapper.strWhere;
            objMigrateFilesBatchSchedulerWrapper.bolIncludeUserRecords = objScheduleJobWrapper.bolIncludeUserRecords;
            if (objScheduleJobWrapper.strBatchType == 'Migrate Files') {
                objMigrateFilesBatchSchedulerWrapper.bolDeleteUploadedRecords = objScheduleJobWrapper.bolDeleteUploadedRecords;
                objMigrateFilesBatchSchedulerWrapper.bolUploadFiles = true;
                strjobId = System.schedule(objScheduleJobWrapper.strName, objScheduleJobWrapper.strCRON, new MigrateFilesBatchScheduler(objMigrateFilesBatchSchedulerWrapper));
            } else if (objScheduleJobWrapper.strBatchType == 'Migrate Files By Object') {
                objMigrateFilesBatchSchedulerWrapper.bolDeleteUploadedRecords = false;
                objMigrateFilesBatchSchedulerWrapper.bolUploadFiles = false;
                strjobId = System.schedule(objScheduleJobWrapper.strName, objScheduleJobWrapper.strCRON, new MigrateFilesBatchScheduler(objMigrateFilesBatchSchedulerWrapper));
            } else if (objScheduleJobWrapper.strBatchType == 'Migrate Attachments') {
                strjobId = System.schedule(objScheduleJobWrapper.strName, objScheduleJobWrapper.strCRON, new MigrateAttachmentsBatchScheduler(objScheduleJobWrapper.strWhere, objScheduleJobWrapper.bolDeleteUploadedRecords));
            }
            objToastWrapper.strMessage = Label.Job_is_scheduled_successfully_Batch_Job_Id_is + ' ' + strjobId;
            objToastWrapper.strVariant = Label.Success;
        } catch (Exception exp) {
            objToastWrapper.strMessage = exp.getMessage();
            objToastWrapper.strVariant = Label.Error;
            ErrorLogger.logException('JobConfigurationsController.scheduleJob', exp);
        }
        return objToastWrapper;
    }
    /**
     * To query the list of scheduled filetranz jobs to display an information to admin.
     * @param - from jobConfigurations LWC
     * @return list<ScheduledJobWrapper> - Scheduled job details
     */
    @AuraEnabled
    public static list<ScheduledJobWrapper> getScheduledJobs() {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to view scheduled jobs.');
        }
        list<ScheduledJobWrapper> lstScheduledJobWrapper = new List<ScheduledJobWrapper>();
        Map<String, AsyncApexJob> mapAsyncJob = new Map<String, AsyncApexJob>();
        try {
            Set<String> setFileTranzSchedulerClasses = getFileTranzSchedulerClassNames();
            list<AsyncApexJob> lstAsyncApexJob = [
				SELECT
					Id,
					ApexClass.Name,
					CronTrigger.CronJobDetail.Name,
					CronTrigger.StartTime,
					CronTrigger.EndTime,
					CronTrigger.CreatedDate,
					CronTrigger.CreatedBy.Name,
					CronTrigger.PreviousFireTime,
					CronTrigger.NextFireTime, JobType
				FROM AsyncApexJob
				WHERE JobType IN ('ScheduledApex') AND CronTrigger.CronJobDetail.Name != NULL
					AND ApexClass.Name IN :setFileTranzSchedulerClasses
				WITH USER_MODE ORDER BY CronTrigger.CreatedDate DESC
			];
            for (AsyncApexJob objAsyncApexJob : lstAsyncApexJob) {
                if (!mapAsyncJob.containsKey(objAsyncApexJob.CronTrigger.CronJobDetail.Name)) {
                    mapAsyncJob.put(objAsyncApexJob.CronTrigger.CronJobDetail.Name, objAsyncApexJob);
                }
            }
            for (String strAsyncJob : mapAsyncJob.KeySet()) {
                AsyncApexJob objAsyncApexJob = mapAsyncJob.get(strAsyncJob);
                ScheduledJobWrapper objScheduledJobWrapper = new ScheduledJobWrapper();
                objScheduledJobWrapper.strJobName = objAsyncApexJob.CronTrigger.CronJobDetail.Name;
                objScheduledJobWrapper.strStartTime = String.valueof(objAsyncApexJob.CronTrigger.StartTime);
                objScheduledJobWrapper.strEndTime = String.valueof(objAsyncApexJob.CronTrigger.EndTime);
                objScheduledJobWrapper.strNextFireTime = String.valueof(objAsyncApexJob.CronTrigger.NextFireTime);
                objScheduledJobWrapper.strPreviousFireTime = String.valueof(objAsyncApexJob.CronTrigger.PreviousFireTime);
                objScheduledJobWrapper.strScheduledDate = String.valueof(objAsyncApexJob.CronTrigger.CreatedDate);
                objScheduledJobWrapper.strScheduledBy = objAsyncApexJob.CronTrigger.CreatedBy.Name;
                lstScheduledJobWrapper.add(objScheduledJobWrapper);
            }
        } catch (Exception exp) {
            ErrorLogger.logException('JobConfigurationsController.getScheduledJobs', exp);
        }
        return lstScheduledJobWrapper;
    }
    /**
     * To query the list of filetranz batch jobs to display an information to admin.
     * @param - from jobConfigurations LWC
     * @return List<BatchStatusWrapper> - Batch job details
     */
    @AuraEnabled(cacheable=true)
    public static List<BatchStatusWrapper> getRunningBatchStatus() {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to view batch job status.');
        }
        List<BatchStatusWrapper> lstBatchStatusWrap = new List<BatchStatusWrapper>();
        try {
            Configuration__c objConfig = [SELECT Id, Long_Value__c, Configuration_Name__c FROM Configuration__c WHERE Configuration_Name__c = 'Batch_Job_Names'  WITH USER_MODE LIMIT 1];
            List<String> setBatchNames = objConfig.Long_Value__c.split('; ');
            List<AsyncApexJob> lstAsyncApexJob = [
				SELECT Id, CreatedDate, status, CompletedDate, ExtendedStatus, Apexclass.Name, JobItemsProcessed, TotalJobItems, NumberOfErrors, createdby.name, JobType
				FROM AsyncApexJob
				WHERE ApexClass.name IN :setBatchNames AND JobType IN ('BatchApex', 'Future') WITH USER_MODE
				ORDER BY CreatedDate DESC
			];
            for (AsyncApexJob objAsyncJob : lstAsyncApexJob) {
                BatchStatusWrapper objBatchStatusWrap = new BatchStatusWrapper();
                objBatchStatusWrap.strJobId = objAsyncJob.Id;
                objBatchStatusWrap.strStatus = objAsyncJob.status;
                objBatchStatusWrap.strJobItemsProcessed = objAsyncJob.JobItemsProcessed;
                objBatchStatusWrap.strTotalJobItems = objAsyncJob.TotalJobItems;
                objBatchStatusWrap.strNumberOfErrors = objAsyncJob.NumberOfErrors;
                objBatchStatusWrap.strCreatedByName = objAsyncJob.Createdby.Name;
                objBatchStatusWrap.strCreatedDate =  String.valueof(objAsyncJob.CreatedDate);
                objBatchStatusWrap.strCompletedDate =  String.valueof(objAsyncJob.CompletedDate);
                objBatchStatusWrap.strExtendedStatus = objAsyncJob.ExtendedStatus;
                objBatchStatusWrap.strJobName = objAsyncJob.Apexclass.Name;
                lstBatchStatusWrap.add(objBatchStatusWrap);
            }
        } catch (Exception exp) {
            ErrorLogger.logException('JobConfigurationsController.getRunningBatchStatus', exp);
        }
        return lstBatchStatusWrap;
    }
        
    /**
     * To abort the filetranz batch jobs.
     * @param lstJobId from jobConfigurations LWC
     * @return ToastWrapper - Success/Error toast message wrapper.
     */
    @AuraEnabled
    public static ToastWrapper abortBatchJob(List<Id> lstJobId) {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to abort batch jobs.');
        }
        ToastWrapper objToastWrapper = new ToastWrapper();
        try {
            // Only abort jobs that are actually FileTranz's own scheduled/batch jobs - never trust
            // client-supplied Ids blindly, or any authenticated user could abort any other package's
            // (or another admin's) scheduled Apex or batch jobs in the org.
            Set<String> setFileTranzSchedulerClasses = getFileTranzSchedulerClassNames();
            Configuration__c objBatchNamesConfig = getBatchJobNamesConfig();
            Set<String> setFileTranzBatchClasses = objBatchNamesConfig != null && objBatchNamesConfig.Long_Value__c != null
                ? new Set<String>(objBatchNamesConfig.Long_Value__c.split('; '))
                : new Set<String>();

            List<AsyncApexJob> lstOwnedJobs = [
                SELECT Id FROM AsyncApexJob
                WHERE Id IN :lstJobId
                    AND (ApexClass.Name IN :setFileTranzSchedulerClasses OR ApexClass.Name IN :setFileTranzBatchClasses)
                WITH USER_MODE
            ];
            for (AsyncApexJob objJob : lstOwnedJobs) {
                System.AbortJob(objJob.Id);
            }
            objToastWrapper.strMessage = Label.Job_s_aborted_Successfully;
            objToastWrapper.strVariant = Label.Success;
        } catch (Exception exp) {
            objToastWrapper.strMessage = exp.getMessage();
            objToastWrapper.strVariant = 'Error';
            ErrorLogger.logException('JobConfigurationsController.abortBatchJob', exp);
        }
        return objToastWrapper;
    }

    private static Configuration__c getBatchJobNamesConfig() {
        List<Configuration__c> lstConfig = [
            SELECT Id, Long_Value__c FROM Configuration__c
            WHERE Configuration_Name__c = 'Batch_Job_Names' WITH USER_MODE LIMIT 1
        ];
        return lstConfig.isEmpty() ? null : lstConfig[0];
    }
    
    /**
     * To execute the selected batch job from jobConfigurations LWC screen.
     * @param strBatchType,strWhere,bolIncludeUserRecords,bolDeleteUploadedRecords,strLastNdays from jobConfigurations LWC
     * @return ToastWrapper - Success/Error toast message to LWC
     */
    @AuraEnabled
    public static ToastWrapper excuteBatchJob(String strExcuteBatchJobWrapper) {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to run batch jobs.');
        }

        ExcuteBatchJobWrapper objExcuteBatchJobWrapper = (ExcuteBatchJobWrapper) JSON.deserialize(strExcuteBatchJobWrapper, ExcuteBatchJobWrapper.class);

        ToastWrapper objToastWrapper = new ToastWrapper();
        list<Configuration__c> lstConfig = [SELECT Id, Long_Value__c, Configuration_Name__c FROM Configuration__c WHERE Configuration_Name__c = :objExcuteBatchJobWrapper.strBatchType WITH USER_MODE];
        String strjobId;
        try {
            if (objExcuteBatchJobWrapper.strBatchType == 'Migrate Attachments' || objExcuteBatchJobWrapper.strBatchType == 'Migrate Attachments By Object') {
                objExcuteBatchJobWrapper.strWhere = objExcuteBatchJobWrapper.strWhere != null ? objExcuteBatchJobWrapper.strWhere : '';
            } else {
                objExcuteBatchJobWrapper.strWhere = (objExcuteBatchJobWrapper.strWhere != null && objExcuteBatchJobWrapper.strWhere != '') ? 'WHERE ' + objExcuteBatchJobWrapper.strWhere : '';
            }
            
            if (objExcuteBatchJobWrapper.strBatchType == 'Migrate Files') {
                strjobId = Database.executeBatch(new MigrateFilesBatch(objExcuteBatchJobWrapper.strWhere, objExcuteBatchJobWrapper.bolIncludeUserRecords, objExcuteBatchJobWrapper.bolDeleteUploadedRecords), 200);
            } else if (objExcuteBatchJobWrapper.strBatchType == 'Migrate Attachments' || objExcuteBatchJobWrapper.strBatchType == 'Migrate Attachments By Object') {
                strjobId = Database.executeBatch(new MigrateAttachmentsBatch(objExcuteBatchJobWrapper.strWhere, objExcuteBatchJobWrapper.bolDeleteUploadedRecords), 1);
            } else if (objExcuteBatchJobWrapper.strBatchType == 'Migrate Files By Object') {
                strjobId = Database.executeBatch(new MigrateCDLFilesBatch(objExcuteBatchJobWrapper.strWhere, objExcuteBatchJobWrapper.bolIncludeUserRecords, objExcuteBatchJobWrapper.bolDeleteUploadedRecords), 200);
            }
            objToastWrapper.strMessage = Label.The_job_initiated_successfully_Id + ' ' + strjobId;
            objToastWrapper.strVariant = Label.Success;
            objToastWrapper.strJobId = strjobId;
        } catch (Exception exp) {
            objToastWrapper.strMessage = exp.getMessage();
            objToastWrapper.strVariant = 'Error';
            ErrorLogger.logException('JobConfigurationsController.excuteBatchJob', exp);
        }
        return objToastWrapper;
    }
    /**
     * To get the batch job details and to show it in UI.
     * @param jobId from jobConfigurations LWC
     * @return List<AsyncApexJob> - Apex job details.
     */
    @AuraEnabled
    public static List<AsyncApexJob> getJobDetails(String jobId) {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to view job details.');
        }
        return [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE Id = :String.escapeSingleQuotes(jobId) WITH USER_MODE];
    }

    // This method is added to check the edition based permission before scheduling the jobs.
    @AuraEnabled(cacheable=true)
    public static Boolean checkEditionPermission() {
        return ConfigurationLimits.isFeatureAvailable('Block_Scheduled_Jobs');
    }

    
    /**
     * To delete the scheduled jobs.
     * @param strJobName from jobConfigurations LWC
     *
     */
    @AuraEnabled
    public static void deleteScheduledJobs(String strJobName) {
        if (!CommonUtilities.isFileTranzAdmin()) {
            throw new AuraHandledException('You do not have permission to delete scheduled jobs.');
        }
        // Verify the named job is actually one of FileTranz's own scheduled jobs before aborting it -
        // otherwise any user could abort any scheduled job in the org just by guessing/enumerating its name.
        Set<String> setFileTranzSchedulerClasses = getFileTranzSchedulerClassNames();
        List<AsyncApexJob> lstOwnedJobs = [
            SELECT CronTriggerId FROM AsyncApexJob
            WHERE JobType = 'ScheduledApex'
                AND CronTrigger.CronJobDetail.Name = :String.escapeSingleQuotes(strJobName)
                AND ApexClass.Name IN :setFileTranzSchedulerClasses
            WITH USER_MODE
            LIMIT 1
        ];
        if (!lstOwnedJobs.isEmpty()) {
            System.abortJob(lstOwnedJobs[0].CronTriggerId);
        }
    }
    
    // To frame the details of Scheduled Jobs in UI format
    public class ScheduledJobWrapper {
        @AuraEnabled
        public String strJobName { get; set; }
        @AuraEnabled
        public String strStartTime { get; set; }
        @AuraEnabled
        public String strEndTime { get; set; }
        @AuraEnabled
        public String strNextFireTime { get; set; }
        @AuraEnabled
        public String strPreviousFireTime { get; set; }
        @AuraEnabled
        public String strScheduledDate { get; set; }
        @AuraEnabled
        public String strScheduledBy { get; set; }
    }
    // To return toast message properties to LWC
    public class ToastWrapper {
        @AuraEnabled
        public String strVariant { get; set; }
        @AuraEnabled
        public String strMessage { get; set; }
        @AuraEnabled
        public String strJobId { get; set; }
    }
    // To frame the details of Batch Jobs in UI format
    public class BatchStatusWrapper {
        @AuraEnabled
        public String strJobId { get; set; }
        @AuraEnabled
        public String strJobName { get; set; }
        @AuraEnabled
        public String strStatus { get; set; }
        @AuraEnabled
        public Integer strJobItemsProcessed { get; set; }
        @AuraEnabled
        public Integer strTotalJobItems { get; set; }
        @AuraEnabled
        public Integer strNumberOfErrors { get; set; }
        @AuraEnabled
        public String strCreatedByName { get; set; }
        @AuraEnabled
        public String strCreatedDate { get; set; }
        @AuraEnabled
        public String strCompletedDate { get; set; }
        @AuraEnabled
        public String strExtendedStatus { get; set; }
    }
    
    
    public class ScheduleJobWrapper {
        @AuraEnabled
        public String strName { get; set;}
        @AuraEnabled
        public String strCRON { get; set;}
        @AuraEnabled
        public String strBatchType { get; set;}
        @AuraEnabled
        public String strWhere { get; set;}
        @AuraEnabled
        public Boolean bolIncludeUserRecords { get; set;}
        @AuraEnabled
        public Boolean bolDeleteUploadedRecords { get; set;}
        @AuraEnabled
        public String strLastNdays { get; set;}
    }
    
    public class ExcuteBatchJobWrapper {
        @AuraEnabled
        public String strBatchType { get; set;}
        @AuraEnabled
        public String strWhere { get; set;}
        @AuraEnabled
        public Boolean bolIncludeUserRecords { get; set;}
        @AuraEnabled
        public Boolean bolDeleteUploadedRecords { get; set;}
        @AuraEnabled
        public String strLastNdays { get; set;}
    }
    
}