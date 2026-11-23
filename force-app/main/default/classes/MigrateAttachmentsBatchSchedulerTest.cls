/*
 * Purpose : Test class for MigrateAttachmentsBatchScheduler class
 * Author  : Giri 
 */
@isTest
public class MigrateAttachmentsBatchSchedulerTest {
    @TestSetup
	static void createTestData() {
        // Account test data
		Account objAcc = new Account(Name = 'Test Account');
        if(Schema.SobjectType.Account.isCreateable()){
            insert objAcc;	
        }
        // Case test data
        Case objCase = new Case();
        objCase.Subject = 'Test';
        objCase.Description = 'Test';
        objCase.Status = 'New'; 
        objCase.Origin = 'Email';
        objCase.Reason = 'New problem';
        objCase.AccountId = objAcc.Id;
        objCase.Subject = 'Test1--Test2';
        if(Schema.SobjectType.Case.isCreateable()){
            insert objCase;
        }
        // External file test data
        External_Files__c objEF = new External_Files__c();
        objEF.File_Type__c = 'txt';
        objEF.File_Name__c = 'Test';
        objEF.File_Id__c = '123456789012345678';
        objEF.UID__c = '123456789012345678';
        objEF.Record_Type__c = 'Attachment';
        objEF.Uploaded_From__c = 'FileTranz';
        if(Schema.SobjectType.External_Files__c.isCreateable()){
            insert objEF;
        }
        // Attachment test data
		Attachment objAttach = new Attachment();
		objAttach.ParentId = objEF.id;
		objAttach.Name = 'Test Attachment for Parent';
		objAttach.Body = Blob.valueOf('Test Data');
        objAttach.contenttype = 'text/html';
        if(Schema.SobjectType.Attachment.isCreateable()){
            insert objAttach;
        }
        // External storage setting test data
		External_Storage_Settings__c objExtStrgSet = new External_Storage_Settings__c();
		objExtStrgSet.Name = 'AWS Sample';
		objExtStrgSet.Access_Key__c = '123456789';
		objExtStrgSet.Secret_Key__c = '123456789';
		objExtStrgSet.Region__c = 'uswest';
		objExtStrgSet.Bucket__c = 'fileTranz';
		objExtStrgSet.File_Retrieve_URL__c = 'fileTranz/uswest/sample.png';
		objExtStrgSet.Active__c = true;
        objExtStrgSet.Expiration_Time__c = 12000;
        objExtStrgSet.Maximum_File_Size__c = 102400; 
        objExtStrgSet.Success_Codes__c = '200; 201';
        if(Schema.SobjectType.External_Storage_Settings__c.isCreateable()){
            insert objExtStrgSet;             
        }
	}
	@isTest
    static void migrateAttachmentsBatchSchedulerMethod1() {
        // Call the MigrateAttachmentsBatchScheduler class
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new UploadAttachmentsMockTest());
            System.schedule('ScheduleUploadAttach Job', '0 0 0 ? * * *', new MigrateAttachmentsBatchScheduler('CreatedDate = TODAY', true));
            Integer intCount = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'ScheduleUploadAttach Job' WITH USER_MODE];
            System.assertEquals(1, intCount,'Expected Count 1');
        Test.stopTest();
    }

	@isTest
	static void migrateAttachmentsBatchSchedulerMethod2() {
         // Call the MigrateAttachmentsBatchScheduler class
        Test.startTest();        
            List<External_Storage_Settings__c> lstESSettings = [SELECT Id, Region__c, Success_Codes__c  FROM External_Storage_Settings__c WITH USER_MODE];
            lstESSettings[0].Success_Codes__c = '';
            update lstESSettings;
            Test.setMock(HttpCalloutMock.class, new UploadAttachmentsMockTest());
            System.schedule('ScheduleUploadAttach Job', '0 0 0 ? * * *', new MigrateAttachmentsBatchScheduler('CreatedDate = TODAY', true));
            Integer intCount = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'ScheduleUploadAttach Job' WITH USER_MODE];
            System.assertEquals(1, intCount,'Expected Count 1');
        Test.stopTest();
	}
    
    // Create the HttpCalloutMock for  Test.setMock
    public class UploadAttachmentsMockTest implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request){
            HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			return response;
        }
    }
}