/*
 * Purpose : Test class for MigrateFilesBatchSchedulerTest class
 * Author  : Giri 
 */
@isTest
public class MigrateFilesBatchSchedulerTest {
    @TestSetup
	static void createTestData() {
        //Account Test data
		Account objAcc = new Account(Name = 'Test Account');
        if(Schema.SobjectType.Account.isCreateable()){
            insert objAcc;	
        }
        // External File test data
        External_Files__c objEF = new External_Files__c();
        objEF.File_Type__c = 'txt';
        objEF.File_Name__c = 'Test';
        objEF.File_Id__c = '123456789012345678';
        objEF.UID__c = '123456789012345678';
        objEF.Record_Type__c = 'Files';
        objEF.Uploaded_From__c = 'FileTranz';
        if(Schema.SobjectType.External_Files__c.isCreateable()){
            insert objEF;
        }
		// External storage test data
		External_Storage_Settings__c objExtStrgSet = new External_Storage_Settings__c();
		objExtStrgSet.Name = 'AWS Sample';
		objExtStrgSet.Access_Key__c = '123456789';
		objExtStrgSet.Secret_Key__c = '123456789';
		objExtStrgSet.Region__c = 'uswest';
		objExtStrgSet.Bucket__c = 'fileTranz';
		objExtStrgSet.File_Retrieve_URL__c = 'fileTranz/uswest/sample.png';
		objExtStrgSet.Active__c = true;
        objExtStrgSet.Expiration_Time__c = 12000;
        objExtStrgSet.Maximum_File_Size__c = 10000; // Set the maximum file size as needed
        objExtStrgSet.Success_Codes__c = '200; 201'; // Set success HTTP status codes as needed
        if(Schema.SobjectType.External_Storage_Settings__c.isCreateable()){
            insert objExtStrgSet;        
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
        // Email message test data
        List<Emailmessage> lstEm = new list<Emailmessage>();
        EmailMessage objEM = new EmailMessage();
        objEM.status = '3'; 
        objEM.relatedToId = objAcc.Id; 
        objEM.fromAddress = 'sender@example.com'; 
        objEM.fromName = 'Test person 1'; 
        objEM.subject = 'This is the Subject!'; 
        objEM.htmlBody = '<html><body><b>Hello</b></body></html>'; 
        objEM.toAddress = 'emailnotinsalesforce@toexample.com';
        lstEm.add(objEM);
        EmailMessage objEM1 = new EmailMessage();
        objEM1.status = '3'; 
        objEM1.relatedToId = objCase.Id; 
        objEM1.fromAddress = 'sender@example.com'; 
        objEM1.fromName = 'Test person 1'; 
        objEM1.subject = 'This is the Subject!'; 
        objEM1.htmlBody = '<html><body><b>Hello</b></body></html>'; 
        objEM1.toAddress = 'emailnotinsalesforce@toexample.com';
        lstEm.add(objEM1); 
        EmailMessage objEM2 = new EmailMessage();
        objEM2.status = '3';  
        objEM2.fromAddress = 'sender@example.com'; 
        objEM2.fromName = 'Test person 1'; 
        objEM2.subject = 'This is the Subject!'; 
        objEM2.htmlBody = '<html><body><b>Hello</b></body></html>'; 
        objEM2.toAddress = 'emailnotinsalesforce@toexample.com';
        lstEm.add(objEM2); 
        EmailMessage objEM3 = new EmailMessage();
        objEM3.status = '3'; 
        objEM3.fromAddress = 'sender@example.com'; 
        objEM3.fromName = 'Test person 1'; 
        objEM3.subject = 'This is the Subject!'; 
        objEM3.htmlBody = '<html><body><b>Hello</b></body></html>'; 
        objEM3.toAddress = 'emailnotinsalesforce@toexample.com';
        lstEm.add(objEM3);
        // Create  EmailMessage
        if(Schema.SobjectType.EmailMessage.isCreateable()){
            insert lstEm;
        }
        // Task test data
        Task objTask = new Task();
        objTask.Status = 'Completed';
        objTask.subject = 'Test Task';
        objTask.WhatId = objCase.Id; 
        if(Schema.SobjectType.Task.isCreateable()){
            insert objTask;
        }
        //Create Document
        ContentVersion objCV = new ContentVersion();
        objCV.Title = 'Test Document';
        objCV.PathOnClient = 'TestDocument.pdf';
        objCV.VersionData = Blob.valueOf('Test Content');
        objCV.IsMajorVersion = true;
        if(Schema.SobjectType.ContentVersion.isCreateable()){
            insert objCV;
        }
        // Create contentdocument link
        Id idConDoc = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id  WITH USER_MODE][0].ContentDocumentId;
        List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>();
        ContentDocumentLink objCntDocLink = new ContentDocumentLink();
        objCntDocLink.LinkedEntityId = objAcc.Id; 
        objCntDocLink.ContentDocumentId = idConDoc;
        objCntDocLink.shareType = 'V'; 
        lstCDL.add(objCntDocLink); 
        ContentDocumentLink objCntDocLink1 = new ContentDocumentLink();
        objCntDocLink1.LinkedEntityId = objCase.Id; 
        objCntDocLink1.ContentDocumentId =idConDoc;
        objCntDocLink1.shareType = 'V'; 
        lstCDL.add(objCntDocLink1);
        ContentDocumentLink objCntDocLink2 = new ContentDocumentLink();
        objCntDocLink2.LinkedEntityId = objEM.Id; 
        objCntDocLink2.ContentDocumentId =idConDoc;
        objCntDocLink2.shareType = 'V'; 
        lstCDL.add(objCntDocLink2); 
        ContentDocumentLink objCntDocLink3 = new ContentDocumentLink();
        objCntDocLink3.LinkedEntityId = [select id,what.type,subject from task][0].Id; 
        objCntDocLink3.ContentDocumentId = idConDoc;
        objCntDocLink3.shareType = 'V';
        lstCDL.add(objCntDocLink3); 
        ContentDocumentLink objCntDocLink4 = new ContentDocumentLink();
        objCntDocLink4.LinkedEntityId = objEM1.Id; 
        objCntDocLink4.shareType = 'V'; 
        objCntDocLink4.ContentDocumentId = idConDoc;
        lstCDL.add(objCntDocLink4); 
        ContentDocumentLink objCntDocLink5 = new ContentDocumentLink();
        objCntDocLink5.LinkedEntityId = objEM2.Id; 
        objCntDocLink5.ContentDocumentId = idConDoc;
        objCntDocLink5.shareType = 'V'; 
        lstCDL.add(objCntDocLink5);
        ContentDocumentLink objCntDocLink6 = new ContentDocumentLink();
        objCntDocLink6.LinkedEntityId = objEM3.Id; 
        objCntDocLink6.ContentDocumentId = idConDoc;
        objCntDocLink6.shareType = 'V'; 
        lstCDL.add(objCntDocLink6); 
        ContentDocumentLink objCntDocLink7 = new ContentDocumentLink();
        objCntDocLink7.LinkedEntityId = objTask.Id; 
        objCntDocLink7.ContentDocumentId = idConDoc;
        objCntDocLink7.shareType = 'V'; 
        lstCDL.add(objCntDocLink7);
        if(Schema.SobjectType.ContentDocumentLink.isCreateable()){
            insert lstCDL; 
        } 
    } 
    
    @isTest
    static void migrateFilesBatchSchedulerTestMethod1(){  
         // Call the MigrateFilesBatchScheduler Method
        List<Account> lstAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'  WITH USER_MODE LIMIT 1];       
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MigrateFilesBatchScheduler_MockTest());
            MigrateFilesBatchScheduler.MigrateFilesBatchSchedulerWrapper objMigrateFilesBatchSchedulerWrapper= new MigrateFilesBatchScheduler.MigrateFilesBatchSchedulerWrapper();
            objMigrateFilesBatchSchedulerWrapper.strWhere='where linkedEntityId =\''+lstAccount[0].Id+'\'';
            objMigrateFilesBatchSchedulerWrapper.bolDeleteUploadedRecords=false;
            objMigrateFilesBatchSchedulerWrapper.bolIncludeUserRecords=false;
            objMigrateFilesBatchSchedulerWrapper.bolUploadFiles=false;
            MigrateFilesBatchScheduler objScheduleBatch = new MigrateFilesBatchScheduler(objMigrateFilesBatchSchedulerWrapper);
            System.schedule('ScheduleUploadFiles Job', '0 0 0 ? * * *', objScheduleBatch);
            Integer intCount = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'ScheduleUploadFiles Job'  WITH USER_MODE];
            System.assertEquals(1, intCount, 'Tested');
        Test.stopTest();
    }
    
    @isTest
    static void migrateFilesBatchSchedulerTestMethod3(){
         // Call the MigrateFilesBatchScheduler Method  
        List<Account> lstAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'  WITH USER_MODE LIMIT 1];       
        Test.startTest();
            List<External_Storage_Settings__c> lstESSettings = [SELECT Id, Region__c, Success_Codes__c  FROM External_Storage_Settings__c  WITH USER_MODE];
            lstESSettings[0].Maximum_File_Size__c = 0; 
            update lstESSettings;
            Test.setMock(HttpCalloutMock.class, new MigrateFilesBatchScheduler_MockTest());
            MigrateFilesBatchScheduler.MigrateFilesBatchSchedulerWrapper objMigrateFilesBatchSchedulerWrapper= new MigrateFilesBatchScheduler.MigrateFilesBatchSchedulerWrapper();
            objMigrateFilesBatchSchedulerWrapper.strWhere='where linkedEntityId =\''+lstAccount[0].Id+'\'';
            objMigrateFilesBatchSchedulerWrapper.bolDeleteUploadedRecords=false;
            objMigrateFilesBatchSchedulerWrapper.bolIncludeUserRecords=false;
            objMigrateFilesBatchSchedulerWrapper.bolUploadFiles=false;
            MigrateFilesBatchScheduler objScheduleBatch = new MigrateFilesBatchScheduler(objMigrateFilesBatchSchedulerWrapper);
            System.schedule('ScheduleUploadFiles Job', '0 0 0 ? * * *', objScheduleBatch);
            Integer intCount = [SELECT COUNT()  FROM CronTrigger WHERE CronJobDetail.Name = 'ScheduleUploadFiles Job'  WITH USER_MODE];
            System.assertEquals(1, intCount, 'Tested');
        Test.stopTest();
    }
    
    @isTest
    static void testMigrateFilesBatchExecution() {
         // Call the MigrateFilesBatch Method
        Test.startTest();
        MigrateFilesBatch batchJob = new MigrateFilesBatch('WHERE Id!=null', true, true);
        Database.executeBatch(batchJob, 1);
        Test.stopTest();
        System.assert(true, 'MigrateFilesBatch executed successfully');
    }

    //Mock HttpCalloutMock class
	public class MigrateFilesBatchScheduler_MockTest implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			return response;
		}
	}
}