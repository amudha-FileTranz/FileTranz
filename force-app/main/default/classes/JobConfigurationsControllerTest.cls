/*
 * Purpose : Test class for JobConfigurationsController class.
 * Author  : Anandhkumar Thangasamy
 */
@IsTest
public class JobConfigurationsControllerTest {
    @TestSetup
    static void createTestData() {
        // Configuration__c Tset data
        Configuration__c objConfig = new Configuration__c();
        objConfig.Configuration_Name__c = 'Batch_Job_Names';
        objConfig.Configuration_Type__c = 'File Configuration';
        objConfig.Long_Value__c = 'MigrateAttachmentsBatch; MigrateFilesBatch; EmptyRecycleBinBatch; LogActivityExportBatch; MigrateCDLFilesBatch; MigrateFileVersionsBatch; DeleteContentDocumentsBatch; DeleteExternalFilesBatch';
        if(Schema.SobjectType.Configuration__c.isCreateable()){
            insert objConfig;
        }
        // External_Storage_Settings__c test data
        External_Storage_Settings__c objESS = new External_Storage_Settings__c();
        objESS.Access_Key__c = '123456789';
        objESS.Secret_Key__c = '123456789';
        objESS.Bucket__c = 'fileTranz';
        objESS.Region__c = 'uswest';
        objESS.File_Retrieve_URL__c = 'fileTranz/uswest/sample.png';
        objESS.Name = 'Sample';
        objESS.Expiration_Time__c = 12000;
        objESS.Storage__c = 's3';
        objESS.Active__c = true;
        objESS.Success_Codes__c = '200';
        objESS.Maximum_File_Size__c = 12000000;
        if(Schema.SobjectType.External_Storage_Settings__c.isCreateable()){
            insert objESS;
        }
        // External_Files__c test data
        External_Files__c objEF = new External_Files__c();
        objEF.File_Type__c = 'txt';
        objEF.File_Name__c = 'Test';
        objEF.File_Id__c = '123456789012345678';
        objEF.Is_Deleted__c = true;
        if(Schema.SobjectType.External_Files__c.isCreateable()){
            insert objEF;
        }
        // Ensure the user running these tests is recognized as a FileTranz admin, since
        // JobConfigurationsController now gates every method on CommonUtilities.isFileTranzAdmin().
        assignPermissionSetIfMissing(UserInfo.getUserId(), 'FileTranz_Admin');
    }

    private static void assignPermissionSetIfMissing(Id userId, String permissionSetName) {
        PermissionSet objPS = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
        List<PermissionSetAssignment> lstExisting = [
            SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetId = :objPS.Id
        ];
        if (lstExisting.isEmpty() && Schema.sObjectType.PermissionSetAssignment.isCreateable()) {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = objPS.Id);
        }
    }
    @isTest
    static void jobScheduleTestMethod () {
        Test.startTest();
        // Test case for scheduleJob()
        Test.setMock(HttpCalloutMock.class, new JobConfigurationsControllerSuccess_MockTest());
        JobConfigurationsController.ScheduleJobWrapper objScheduleJobWrapper = new JobConfigurationsController.ScheduleJobWrapper();
        objScheduleJobWrapper.strName = 'Migrate Files';
        objScheduleJobWrapper.strCRON = '0 0 0 ? * * *';
        objScheduleJobWrapper.strBatchType = 'Migrate Files';
        objScheduleJobWrapper.strWhere = 'Id!=null';
        objScheduleJobWrapper.bolIncludeUserRecords = false;
        objScheduleJobWrapper.bolDeleteUploadedRecords = false;
        objScheduleJobWrapper.strLastNdays = '0';
        JobConfigurationsController.ToastWrapper objToastWrapper = JobConfigurationsController.scheduleJob(JSON.serialize(objScheduleJobWrapper));
        Assert.areEqual('Success', objToastWrapper.strVariant,'Job schedule Successfully');
        // Test case for getScheduledJobs()
        List<JobConfigurationsController.ScheduledJobWrapper> lstScheduledJobWrapper = JobConfigurationsController.getScheduledJobs();
        Assert.areEqual(1, lstScheduledJobWrapper.size(),'Expected Job Sixe 1');
        // Test case for abortAllSelectedJobs()
        JobConfigurationsController.deleteScheduledJobs('Migrate Files');
        // JobConfigurationsController.ToastWrapper objToastWrapper1 = JobConfigurationsController.abortAllSelectedJobs(new List<String>{'Migrate Files'});
        // Assert.areEqual('Success', objToastWrapper1.strVariant, 'Clear Recycle Bin Job Abort Failed!');
        JobConfigurationsController.ExcuteBatchJobWrapper objExcuteBatchJobWrapper = new JobConfigurationsController.ExcuteBatchJobWrapper();
        objExcuteBatchJobWrapper.strBatchType = 'Migrate Files';
        objExcuteBatchJobWrapper.strWhere = 'Id!=null';
        objExcuteBatchJobWrapper.bolIncludeUserRecords = false;
        objExcuteBatchJobWrapper.bolDeleteUploadedRecords = false;
        objExcuteBatchJobWrapper.strLastNdays = '0';
        // Test case for excuteBatchJob()
        JobConfigurationsController.ToastWrapper objToastWrapper2 = JobConfigurationsController.excuteBatchJob(JSON.serialize(objExcuteBatchJobWrapper));
        Assert.areEqual('Success', objToastWrapper2.strVariant,'Expected String Success');
        List<Id> lstIds = new List<Id>();
        lstIds.add(objToastWrapper.strJobId);
        // Test case for abortBatchJob()
        JobConfigurationsController.ToastWrapper objToastWrappermssg = JobConfigurationsController.abortBatchJob(lstIds);
        Assert.areEqual(True,objToastWrappermssg!= null,'Tested');
        JobConfigurationsController.abortBatchJob(null);
        // JobConfigurationsController.abortAllSelectedJobs(null);
        // Test case for scheduleJob()
        JobConfigurationsController.ScheduleJobWrapper objScheduleJobWrapper1 = new JobConfigurationsController.ScheduleJobWrapper();
        objScheduleJobWrapper1.strName = '';
        objScheduleJobWrapper1.strCRON = '';
        objScheduleJobWrapper1.strBatchType = '';
        objScheduleJobWrapper1.strWhere = null;
        objScheduleJobWrapper1.bolIncludeUserRecords = false;
        objScheduleJobWrapper1.bolDeleteUploadedRecords = false;
        objScheduleJobWrapper1.strLastNdays = null;
        JobConfigurationsController.ToastWrapper objToastWrapper3 =JobConfigurationsController.scheduleJob(JSON.serialize(objScheduleJobWrapper1));
        Test.stopTest();
    }
    @isTest
    static void migrateFilesBatchTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new JobConfigurationsControllerSuccess_MockTest());
        // Test case for scheduleJob()
        JobConfigurationsController.ScheduleJobWrapper objScheduleJobWrapper = new JobConfigurationsController.ScheduleJobWrapper();
        objScheduleJobWrapper.strName = 'Migrate Files';
        objScheduleJobWrapper.strCRON = '0 0 0 ? * * *';
        objScheduleJobWrapper.strBatchType = 'Migrate Files';
        objScheduleJobWrapper.strWhere = 'Id!=null';
        objScheduleJobWrapper.bolIncludeUserRecords = true;
        objScheduleJobWrapper.bolDeleteUploadedRecords = true;
        objScheduleJobWrapper.strLastNdays = '0';
        JobConfigurationsController.ToastWrapper objToastWrapper = JobConfigurationsController.scheduleJob(JSON.serialize(objScheduleJobWrapper));
        Assert.areEqual('Success', objToastWrapper.strVariant, 'Migrate Files Batch Schedule Failed!');
        // Test case for excuteBatchJob()
        JobConfigurationsController.ExcuteBatchJobWrapper objExcuteBatchJobWrapper = new JobConfigurationsController.ExcuteBatchJobWrapper();
        objExcuteBatchJobWrapper.strBatchType = 'Migrate Files';
        objExcuteBatchJobWrapper.strWhere = 'Id!=null';
        objExcuteBatchJobWrapper.bolIncludeUserRecords = false;
        objExcuteBatchJobWrapper.bolDeleteUploadedRecords = false;
        objExcuteBatchJobWrapper.strLastNdays = '0';
        JobConfigurationsController.ToastWrapper objToastWrapper2 = JobConfigurationsController.excuteBatchJob(JSON.serialize(objExcuteBatchJobWrapper));
        Assert.areEqual('Success', objToastWrapper2.strVariant, 'Migrate Files Batch Execution Failed!');
        ErrorLogger.LogErrorWrapper objLogErrorWrapper = new ErrorLogger.LogErrorWrapper();
        objLogErrorWrapper.relatedTo = 'JobConfigurationsController.migrateFilesBatchTest';
        objLogErrorWrapper.summary = '';
        objLogErrorWrapper.message = 'Error';
        objLogErrorWrapper.batchJobId = '';
        objLogErrorWrapper.recordIds = '';
        objLogErrorWrapper.statusCode = '';
        ErrorLogger.logError(JSON.serialize(objLogErrorWrapper));
        Test.stopTest();
    }
    @isTest
    static void migrateFilesByObjectBatchTest() {
        Account acc=new Account(Name='Test');
        insert acc;
        Test.startTest();
        // Test case for scheduleJob()
        Test.setMock(HttpCalloutMock.class, new JobConfigurationsControllerSuccess_MockTest());
        JobConfigurationsController.ScheduleJobWrapper objScheduleJobWrapper = new JobConfigurationsController.ScheduleJobWrapper();
        objScheduleJobWrapper.strName = 'Migrate Files By Object';
        objScheduleJobWrapper.strCRON = '0 0 0 ? * * *';
        objScheduleJobWrapper.strBatchType = 'Migrate Files By Object';
        objScheduleJobWrapper.strWhere = 'LinkedEntityId IN (SELECT Id FROM Account )';
        objScheduleJobWrapper.bolIncludeUserRecords = false;
        objScheduleJobWrapper.bolDeleteUploadedRecords = true;
        objScheduleJobWrapper.strLastNdays = '0';
        JobConfigurationsController.ToastWrapper objToastWrapper = JobConfigurationsController.scheduleJob(JSON.serialize(objScheduleJobWrapper));
        Assert.areEqual('Success', objToastWrapper.strVariant, 'Migrate Files Batch Schedule Failed!');
        // Test case for excuteBatchJob()
        /* JobConfigurationsController.ExcuteBatchJobWrapper objExcuteBatchJobWrapper = new JobConfigurationsController.ExcuteBatchJobWrapper();
        objExcuteBatchJobWrapper.strBatchType = 'Migrate Files By Object';
        objExcuteBatchJobWrapper.strWhere = 'Id!=null';
        objExcuteBatchJobWrapper.bolIncludeUserRecords = false;
        objExcuteBatchJobWrapper.bolDeleteUploadedRecords = false;
        objExcuteBatchJobWrapper.strLastNdays = '0';
        JobConfigurationsController.ToastWrapper objToastWrapper2 = JobConfigurationsController.excuteBatchJob(JSON.serialize(objExcuteBatchJobWrapper));
        Assert.areEqual('Success', objToastWrapper2.strVariant, 'Migrate Files Batch Execution Failed!');
        JobConfigurationsController.ExcuteBatchJobWrapper objExcuteBatchJobWrapper1 = new JobConfigurationsController.ExcuteBatchJobWrapper();
        objExcuteBatchJobWrapper1.strBatchType = '';
        objExcuteBatchJobWrapper1.strWhere = null;
        objExcuteBatchJobWrapper1.bolIncludeUserRecords = false;
        objExcuteBatchJobWrapper1.bolDeleteUploadedRecords = false;
        objExcuteBatchJobWrapper1.strLastNdays = null;
        JobConfigurationsController.ToastWrapper objToastWrapper3 = JobConfigurationsController.excuteBatchJob(JSON.serialize(objExcuteBatchJobWrapper1)); */
        Test.stopTest();
    }
    @isTest
    static void migrateAttachmentsBatchTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new JobConfigurationsControllerSuccess_MockTest());
        // Test case for scheduleJob()
        JobConfigurationsController.ScheduleJobWrapper objScheduleJobWrapper = new JobConfigurationsController.ScheduleJobWrapper();
        objScheduleJobWrapper.strName = 'Migrate Attachments';
        objScheduleJobWrapper.strCRON = '0 0 0 ? * * *';
        objScheduleJobWrapper.strBatchType = 'Migrate Attachments';
        objScheduleJobWrapper.strWhere = '';
        objScheduleJobWrapper.bolIncludeUserRecords = true;
        objScheduleJobWrapper.bolDeleteUploadedRecords = true;
        objScheduleJobWrapper.strLastNdays = '0';
        JobConfigurationsController.ToastWrapper objToastWrapper = JobConfigurationsController.scheduleJob(JSON.serialize(objScheduleJobWrapper));
        Assert.areEqual('Success', objToastWrapper.strVariant, 'Migrate Attachments Batch Schedule Failed!');
        // Test case for excuteBatchJob()
        JobConfigurationsController.ExcuteBatchJobWrapper objExcuteBatchJobWrapper = new JobConfigurationsController.ExcuteBatchJobWrapper();
        objExcuteBatchJobWrapper.strBatchType = 'Migrate Attachments';
        objExcuteBatchJobWrapper.strWhere = '';
        objExcuteBatchJobWrapper.bolIncludeUserRecords = false;
        objExcuteBatchJobWrapper.bolDeleteUploadedRecords = false;
        objExcuteBatchJobWrapper.strLastNdays = '0';
        JobConfigurationsController.ToastWrapper objToastWrapper2 = JobConfigurationsController.excuteBatchJob(JSON.serialize(objExcuteBatchJobWrapper));
        Assert.areEqual('Success', objToastWrapper2.strVariant, 'Migrate Attachments Batch Execution Failed!');
        List<AsyncApexJob> lstJobs = JobConfigurationsController.getJobDetails(objToastWrapper2.strJobId);
        JobConfigurationsController.ExcuteBatchJobWrapper objExcuteBatchJobWrapper1 = new JobConfigurationsController.ExcuteBatchJobWrapper();
        objExcuteBatchJobWrapper1.strBatchType = '';
        objExcuteBatchJobWrapper1.strWhere = null;
        objExcuteBatchJobWrapper1.bolIncludeUserRecords = false;
        objExcuteBatchJobWrapper1.bolDeleteUploadedRecords = false;
        objExcuteBatchJobWrapper1.strLastNdays = null;
        JobConfigurationsController.ToastWrapper objToastWrapper3 = JobConfigurationsController.excuteBatchJob(JSON.serialize(objExcuteBatchJobWrapper1));
        List<JobConfigurationsController.BatchStatusWrapper> objBatchStatusWrapper = JobConfigurationsController.getRunningBatchStatus();
        Test.stopTest();
    }
    @isTest
    static void testvalidateQuery() {
        // Test case for validateQuery
        Test.startTest();
        String strQuery = 'SELECT Id FROM External_Files__c';
        String strMssg = JobConfigurationsController.validateQuery(strQuery, false);
        Assert.areEqual(True,strMssg == 'Success','Tested');
        String strQuery1 = 'SELECT Id FROM External_Files__c';
        JobConfigurationsController.validateQuery(strQuery1, false);
        String strQuery2 = 'SELECT Id FROM Account ';
        JobConfigurationsController.validateQuery(strQuery2, false);
        String strMssg2 = JobConfigurationsController.validateQuery('null', false);
        Test.stopTest();
    }
    
    // Mock class for positive use case
    public class JobConfigurationsControllerSuccess_MockTest implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            return response;
        }
    }
    // Mock class for negative use case
    public class JobConfigurationsControllerError_MockTest implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            return response;
        }
    }
}