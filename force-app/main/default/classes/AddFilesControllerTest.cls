/*
 * Purpose : Test class for AddFilesController class.
 * Author  : Giri
 */
@isTest
public class AddFilesControllerTest {
    @TestSetup
    static void createTestData(){
        // Account Test data
        Account objAccount = new Account(Name = 'Test Account');
        if(Schema.sObjectType.Account.fields.Name.isCreateable()){
            insert objAccount;
        }
        // External_Files__c Test data
        List<External_Files__c> lstEF = new List<External_Files__c>();
        External_Files__c objEF1 = new External_Files__c();
        objEF1.File_Type__c = 'txt';
        objEF1.File_Name__c = 'Test File 1';
        objEF1.File_Id__c = '123456789012345678';
        objEF1.UID__c = '123456789012345678';
        objEF1.Record_Type__c = 'Files';
        objEF1.Uploaded_From__c = 'FileTranz';
        lstEF.add(objEF1);
        
        External_Files__c objEF2 = new External_Files__c();
        objEF2.File_Type__c = 'txt';
        objEF2.File_Name__c = 'Test File 2';
        objEF2.File_Id__c = '123456789012345679';
        objEF2.UID__c = '123456789012345679';
        objEF2.Record_Type__c = 'Files';
        objEF2.Uploaded_From__c = 'FileTranz';
        lstEF.add(objEF2);
        if(Schema.sObjectType.External_Files__c.isCreateable()){
            insert lstEF;
        }
        // External_File_Version__c Test data
        External_File_Version__c objEFV = new External_File_Version__c();
        objEFV.External_Files__c = lstEF[0].Id;
        objEFV.Is_Latest__c = true;
        objEFV.Version_Number__c = 1;
        objEFV.Size__c = '1 KB';
        objEFV.Size_Bytes__c = 30000;
        objEFV.File_Location_URL__c = 'https://sfdc-filetranz.s3.eu-north-1.amazonaws.com/0015i00000o2KjGAAU/test.txt';
        if(Schema.sObjectType.External_File_Version__c.isCreateable()){
            insert objEFV;
        }
        // External_File_Link__c Test data
        External_File_Link__c objEFL = new External_File_Link__c();
        objEFL.Object_Type__c = 'Account';
        objEFL.External_Files__c = lstEF[0].Id;
        objEFL.Related_To__c = objAccount.Id;
        if(Schema.sObjectType.External_File_Link__c.isCreateable()){
            insert objEFL;
        }
    }
    
    @isTest
    public static void addFilesControllerTestMethod(){
        Test.startTest();
        // To query the account and pass to the getExternalFiles method
        Account objAcc = [SELECT Id, Name FROM Account WHERE Name ='Test Account' WITH USER_MODE LIMIT 1];
        List<CommonUtilities.ExternalFilesWrapper> lstExternalFilesWrapper = AddFilesController.getExternalFiles(objAcc.Id, '');
        // Assert to test the AddFilesController
        Assert.areEqual(true,lstExternalFilesWrapper != null,'Tested');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetExternalFilesException() {
        // Set up test data
        String strRecordId = 'a0123456789ABC';
        String strSearchKey = 'Test';
        // Create a fake user to induce an exception with System.runAs
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User objStandardUser = new User();
        objStandardUser.Alias = 'tuser';
        objStandardUser.Email='testuser@example.com';
        objStandardUser.EmailEncodingKey='UTF-8';
        objStandardUser.LastName='TestUser';
        objStandardUser.LanguageLocaleKey='en_US';
        objStandardUser.LocaleSidKey='en_US';
        objStandardUser.ProfileId = objProfile.Id;
        objStandardUser.TimeZoneSidKey='America/Los_Angeles';
        objStandardUser.UserName='testuser' + Math.random() + '@example.com';
        insert objStandardUser;
        Test.startTest();
        System.runAs(objStandardUser) {
            // Call the method and expect it to handle the exception gracefully
            List<CommonUtilities.ExternalFilesWrapper> result = AddFilesController.getExternalFiles(strRecordId, strSearchKey);
            // Since an exception should occur, the result should be empty
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(0, result.size(), 'Result list should be empty due to exception');
        }
        Test.stopTest();
    }
}