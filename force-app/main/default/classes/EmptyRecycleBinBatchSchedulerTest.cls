/*
 * Purpose : Test class for EmptyRecycleBinBatchScheduler class
 * Author  : Giri 
 */
@isTest
public class EmptyRecycleBinBatchSchedulerTest {
    @TestSetup
    static void createTestData() {
        // Account Test data
		Account objAccount = new Account(Name = 'Test Account');
		if(Schema.SobjectType.Account.isCreateable()){
			insert objAccount;
		}
        // External_Storage_Settings__c test data
        External_Storage_Settings__c objESS = new External_Storage_Settings__c();
		objESS.Name = 'AWS Sample';
		objESS.Access_Key__c = '123456789';
		objESS.Secret_Key__c = '123456789';
		objESS.Region__c = 'uswest';
		objESS.Bucket__c = 'fileTranz';
		objESS.File_Retrieve_URL__c = 'fileTranz/uswest/sample.png';
		objESS.Active__c = true;
        objESS.Expiration_Time__c = 12000;
        objESS.Maximum_File_Size__c = 102400; 
        objESS.Success_Codes__c = '200; 201'; 
		if(Schema.SobjectType.External_Storage_Settings__c.isCreateable()){
			insert objESS;
		}
        // External_Files__c test data
		List<External_Files__c> lstEF = new List<External_Files__c>();
		External_Files__c objEF1 = new External_Files__c();
		objEF1.File_Type__c = 'txt';
		objEF1.File_Name__c = 'Test File 1';
		objEF1.File_Id__c = '123456789012345678';
		objEF1.UID__c = '123456789012345678';
		objEF1.Record_Type__c = 'Files';
		objEF1.Uploaded_From__c = 'FileTranz';
        objEF1.Is_Deleted__c = true;
		lstEF.add(objEF1);

		External_Files__c objEF2 = new External_Files__c();
		objEF2.File_Type__c = 'txt';
		objEF2.File_Name__c = 'Test File 2';
		objEF2.File_Id__c = '123456789012345679';
		objEF2.UID__c = '123456789012345679';
		objEF2.Record_Type__c = 'Files';
		objEF2.Uploaded_From__c = 'FileTranz';
		lstEF.add(objEF2);
		if(Schema.SobjectType.External_Files__c.isCreateable()){
			insert lstEF;
		}
		// External_File_Version__c test data
		External_File_Version__c objEFV = new External_File_Version__c();
		objEFV.External_Files__c = lstEF[0].Id;
		objEFV.Is_Latest__c = true;
		objEFV.Version_Number__c = 1;
		objEFV.Size__c = '1 KB';
		objEFV.Size_Bytes__c = 30000;
		objEFV.File_Location_URL__c = 'https://sfdc-filetranz.s3.eu-north-1.amazonaws.com/0015i00000o2KjGAAU/test.txt';
		if(Schema.SobjectType.External_File_Version__c.isCreateable()){
			insert objEFV;
		}
		// External_File_Link__c test data
		External_File_Link__c objEFL = new External_File_Link__c();
		objEFL.Object_Type__c = 'Account';
		objEFL.External_Files__c = lstEF[0].Id;
		objEFL.Related_To__c = ObjAccount.Id;
        objEFL.Is_Deleted__c = true;
		if(Schema.SobjectType.External_File_Link__c.isCreateable()){
			insert objEFL;
		}
		// Configuration__c test data
		Configuration__c objConfig = new Configuration__c();
		objConfig.Configuration_Type__c ='File Configuration';
		objConfig.Configuration_Name__c = 'Clear_Recycle_Bin_In';
		objConfig.Long_Value__c = '1';
		if (Schema.SobjectType.Configuration__c.isCreateable()) {
			insert objConfig;
		}
    }
	@isTest
    static void emptyRecycleBinBatchSchedulerPostiveMethod() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PositiveMockTest());
            System.schedule('ClearRecycleBinBatch Job', '0 0 0 * * ?',  new EmptyRecycleBinBatchScheduler()); 
            Integer intCount = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'ClearRecycleBinBatch Job' WITH USER_MODE];
            System.assertEquals(1, intCount, 'intCount must be 1');
        Test.stopTest();
	}
    @isTest
    static void emptyRecycleBinBatchSchedulerNegativeMethod() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new NegativeMockTest());
            System.schedule('ClearRecycleBinBatch Job', '0 0 0 * * ?', new EmptyRecycleBinBatchScheduler());  
            Integer intCount = [SELECT COUNT()  FROM CronTrigger WHERE CronJobDetail.Name = 'ClearRecycleBinBatch Job' WITH USER_MODE];
            System.assertEquals(1, intCount, 'intCount must be 1');
			DeleteExternalFilesBatch objDeleteExternalFilesBatch = new DeleteExternalFilesBatch('', new Set<Id>());
        Test.stopTest();
	}

    // Mock class for positive use case
	 public class PositiveMockTest implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request){
            HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			return response;
        }
    }

    // Mock class for negative use case
	public class NegativeMockTest implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			return response;
		}
	}
}