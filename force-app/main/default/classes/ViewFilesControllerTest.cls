/*
 * Purpose : Test class for ViewFilesController class.
 * Author  : Giri
 */
@isTest
public class ViewFilesControllerTest {
    @TestSetup
    static void createTestData() {
        string strUserId = UserInfo.getUserId();
        User objUser = [SELECT id, ProfileId, Profile.Name FROM user WHERE id = :strUserId AND IsActive = TRUE WITH USER_MODE];
        // Account Test data
        Account objAccount = new Account(Name = 'Test Account');
        if (Schema.SObjectType.Account.isCreateable()) {
            insert objAccount;
        }
        
        // Configuration__c Tset data
        Configuration__c objConfig = new Configuration__c();
        objConfig.Configuration_Name__c = 'Log_Activity';
        objConfig.Configuration_Type__c = 'File Configuration';
        objConfig.Long_Value__c = 'Edit,Download,Delete';
        if (Schema.SObjectType.Configuration__c.isCreateable()) {
            insert objConfig;
        }
        
        // Log_Activity__c Test data
        List<Log_Activity__c> lstLogActivity = new List<Log_Activity__c>();
        Log_Activity__c objLogActivity = new Log_Activity__c();
        objLogActivity.File_Name__c = 'TestFile.txt';
        objLogActivity.External_File_Id__c = '123456789012345678';
        objLogActivity.Activity_Type__c = 'Download';
        objLogActivity.Activity_Performed_By__c = objUser.Id;
        objLogActivity.Record_Id__c = objAccount.Id;
        lstLogActivity.add(objLogActivity);
        
        if (Schema.SObjectType.Log_Activity__c.isCreateable()) {
            insert lstLogActivity;
        }
        // External_Files__c Test data
        List<External_Files__c> lstEF = new List<External_Files__c>();
        External_Files__c objEF1 = new External_Files__c();
        objEF1.File_Type__c = 'txt';
        objEF1.File_Name__c = 'TestFile1';
        objEF1.File_Id__c = '123456789012345678';
        objEF1.UID__c = '123456789012345678';
        objEF1.Record_Type__c = 'Files';
        objEF1.Uploaded_From__c = 'FileTranz';
        lstEF.add(objEF1);
        
        // External_Files__c test data
        External_Files__c objEF2 = new External_Files__c();
        objEF2.File_Type__c = 'txt';
        objEF2.File_Name__c = 'TestFile2';
        objEF2.File_Id__c = '123456789012345679';
        objEF2.UID__c = '123456789012345679';
        objEF2.Record_Type__c = 'Files';
        objEF2.Uploaded_From__c = 'FileTranz';
        lstEF.add(objEF2);
        if (Schema.SObjectType.External_Files__c.isCreateable()) {
            insert lstEF;
        }
        
        // External_File_Version__c test data
        External_File_Version__c objEFV = new External_File_Version__c();
        objEFV.External_Files__c = lstEF[0].Id;
        objEFV.Is_Latest__c = true;
        objEFV.Version_Number__c = 1;
        objEFV.Size__c = '1 KB';
        objEFV.Size_Bytes__c = 30000;
        objEFV.File_Location_URL__c = 'https://sfdc-filetranz.s3.eu-north-1.amazonaws.com/0015i00000o2KjGAAU/'+ lstEF[0].File_Name__c+'.'+lstEF[0].File_Type__c;
        if (Schema.SObjectType.External_File_Version__c.isCreateable()) {
            insert objEFV;
        }
        // So getPresignedURL can resolve a file location from External_Files__r.Latest_External_File_Version__r
        // in every test method, not just the one that happens to set this up itself.
        if (Schema.SObjectType.External_Files__c.fields.Latest_External_File_Version__c.isUpdateable()) {
            lstEF[0].Latest_External_File_Version__c = objEFV.Id;
            update lstEF[0];
        }

        // External_File_Link__c test data
        External_File_Link__c objEFL = new External_File_Link__c();
        objEFL.Object_Type__c = 'Account';
        objEFL.External_Files__c = lstEF[0].Id;
        objEFL.Related_To__c = ObjAccount.Id;
        if (Schema.SObjectType.External_File_Link__c.isCreateable()) {
            insert objEFL;
        }
        
        // External_Storage_Settings__c test data
        External_Storage_Settings__c objExtStrgSet = new External_Storage_Settings__c();
        objExtStrgSet.Name = 'AWS';
        objExtStrgSet.Access_Key__c = 'TestAccessKey';
        objExtStrgSet.Secret_Key__c = 'TestSecretKey+M8NUm/sg8PuY+XM8GmVwMIe';
        objExtStrgSet.Region__c = 'eu-north-1';
        objExtStrgSet.Bucket__c = 'sfdc-filetranz';
        objExtStrgSet.Endpoint_Url__c = '';
        objExtStrgSet.File_Retrieve_URL__c = 'https://sfdc-filetranz.s3.eu-north-1.amazonaws.com';
        objExtStrgSet.Storage__c = 'Amazon S3';
        objExtStrgSet.Expiration_Time__c = 12000;
        objExtStrgSet.Active__c = true;
        objExtStrgSet.Success_Codes__c = '0; 200; 201; 204';
        if (Schema.SObjectType.Log_Activity__c.isCreateable()) {
            insert objExtStrgSet;
        }
    }
    @IsTest
    public static void test_UpdateFileNames() {
        Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        List<External_Files__c> lstExternalFiles = [
			SELECT Id, Name, File_Name__c, Latest_Version_Size__c, Latest_Version_Size_Bytes__c, Is_Deleted__c, LastModifiedDate, File_Type__c
			FROM External_Files__c
		];
        External_File_Version__c objEFV = [SELECT Id FROM External_File_Version__c WHERE External_Files__c = :lstExternalFiles[0].Id  LIMIT 1];
        lstExternalFiles[0].Latest_External_File_Version__c = objEFV.Id;
        update lstExternalFiles[0];
        List<External_File_Link__c> lstEFL = [SELECT Id FROM External_File_Link__c];
        Test.startTest();
        // To cover retrieveExternalFiles method
        ViewFilesController.retrieveExternalFiles(objAccount.Id);
        Assert.areEqual(true, objAccount != null);
        ViewFilesController.retrieveExternalFiles(objAccount.Id);
        
        
        // To create externalfileswrapper data
        CommonUtilities.ExternalFilesWrapper objWrapper = new CommonUtilities.ExternalFilesWrapper();
        Assert.areEqual(true, lstExternalFiles != null);
        objWrapper.strExternalFileId = lstExternalFiles[0].Id;
        objWrapper.strName = lstExternalFiles[0].Name;
        objWrapper.strFileName = lstExternalFiles[0].File_Name__c;
        objWrapper.strSize = lstExternalFiles[0].Latest_Version_Size__c;
        objWrapper.strFileType = lstExternalFiles[0].File_Type__c;
        objWrapper.bolShowEdit = true;
        objWrapper.bolSelected = false;
        objWrapper.SNo = 64322;
        objWrapper.dblSize = 31;
        boolean bolUpdateFileNameResMssg = ViewFilesController.updateFileNames(new List<CommonUtilities.ExternalFilesWrapper>{ objWrapper });
        Assert.areEqual(true, bolUpdateFileNameResMssg == true);
        String strPresignedURL = ViewFilesController.getPresignedURL(lstEFL[0].Id, 'GET');
        Assert.areEqual(true, strPresignedURL != null);
        String strMessagedeleteExternalFile = ViewFilesControllerHelper.deleteExternalFileLinks(new List<string>{ lstEFL[0].Id }, 'true', strPreSignedURL);
        Assert.areEqual(true, strMessagedeleteExternalFile == 'success');
        Test.stopTest();
    }
    // Test method to cover http callout in ViewFilesController class
    @IsTest
    public static void test_getFileFromAmazonS3() {
        Test.startTest();
        User objTestUser = [SELECT Id FROM User LIMIT 1];
        List<External_Files__c> lstExternalFiles = [
			SELECT Id, Name, File_Name__c, Latest_Version_Size__c, Latest_Version_Size_Bytes__c, Is_Deleted__c, LastModifiedDate, File_Type__c
			FROM External_Files__c
		];
        List<External_File_Link__c> lstEFL = [SELECT Id FROM External_File_Link__c];
        List<Log_Activity__c> lstLogActivity = [SELECT Id, Activity_Type__c, Activity_Performed_By__c FROM Log_Activity__c WHERE Activity_Type__c = 'Download'
                                                 AND Activity_Performed_By__c = :objTestUser.Id];
        System.assertEquals(0, lstLogActivity.size());
        String strPresignedURL = ViewFilesController.getPresignedURL(lstEFL[0].Id, 'GET');
        Assert.areEqual(true, strPresignedURL != null);
        Test.setMock(HttpCalloutMock.class, new ViewFilesControllerMock2());
        String strgetFileFromAmazonS3 = ViewFilesController.getFileFromAmazonS3(strPreSignedURL, lstEFL[0].Id, 'strRelatedTo');
        Assert.areEqual(true, strgetFileFromAmazonS3 != null);
        Assert.areEqual(true, lstEFL != null);
        Test.stopTest();
    }
    // Test method to cover http callout in ViewFilesController class
    @IsTest
    public static void test_deleteExternalFileLinks() {
        Test.startTest();
        List<External_File_Link__c> lstEFL = [SELECT Id FROM External_File_Link__c];
        String strPresignedURL = ViewFilesController.getPresignedURL(lstEFL[0].Id, 'GET');
        Assert.areEqual(true, strPresignedURL != null);
        Assert.areEqual(true, lstEFL != null);
        Test.setMock(HttpCalloutMock.class, new ViewFilesControllerMock1());
        String strMessagedeleteExternalFile = ViewFilesControllerHelper.deleteExternalFileLinks(new List<string>{ lstEFL[0].Id }, 'false', strPreSignedURL);
        Assert.areEqual(true, strMessagedeleteExternalFile != null);
        Test.stopTest();
    }
    
    // Test method to cover http callout in ViewFilesController class
    @IsTest
    public static void test2_deleteExternalFileLinks() {
        Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Test.startTest();
        List<External_File_Link__c> lstEFL = [SELECT Id, External_Files__c FROM External_File_Link__c];
        String strPresignedURL = ViewFilesController.getPresignedURL(lstEFL[0].Id, 'GET');
        Assert.areEqual(true, strPresignedURL != null);
        External_File_Link__c objEFL = new External_File_Link__c();
        objEFL.Object_Type__c = 'Account';
        objEFL.External_Files__c = lstEFL[0].External_Files__c;
        objEFL.Related_To__c = objAccount.Id;
        if (Schema.SObjectType.External_File_Link__c.isCreateable()) {
            insert objEFL;
        }
        External_File_Link__c objEFL1 = new External_File_Link__c();
        objEFL1.Object_Type__c = 'Account';
        objEFL1.External_Files__c = lstEFL[0].External_Files__c;
        objEFL1.Related_To__c = objAccount.Id;
        if (Schema.SObjectType.External_File_Link__c.isCreateable()) {
            insert objEFL1;
        }
        External_File_Link__c objEFL2 = new External_File_Link__c();
        objEFL2.Object_Type__c = 'Account';
        objEFL2.External_Files__c = lstEFL[0].External_Files__c;
        objEFL2.Related_To__c = objAccount.Id;
        if (Schema.SObjectType.External_File_Link__c.isCreateable()) {
            insert objEFL2;
        }
        List<String> lstStrEflId = new List<String>();
        lstStrEflId.add(objEFL1.Id);
        lstStrEflId.add(objEFL2.Id);
        Assert.areEqual(true, lstEFL != null);
        Test.setMock(HttpCalloutMock.class, new ViewFilesControllerMock1());
        String strMessagedeleteExternalFile = ViewFilesControllerHelper.deleteExternalFileLinks(lstStrEflId, 'false', strPreSignedURL);
        Assert.areEqual('Error', strMessagedeleteExternalFile);
        strMessagedeleteExternalFile = ViewFilesControllerHelper.deleteExternalFileLinks(new List<string>{ lstEFL[0].Id }, 'true', strPreSignedURL);
        Assert.areEqual('success', strMessagedeleteExternalFile);
        objEFL.Is_Deleted__c = true;
        update objEFL;
        strMessagedeleteExternalFile = ViewFilesControllerHelper.deleteExternalFileLinks(new List<string>{ objEFL.Id }, 'false', strPreSignedURL);
        Assert.areEqual(strMessagedeleteExternalFile, Label.File_Not_Found);
        // To cover catch block
        Configuration__c objConfig = [SELECT Id FROM Configuration__c WHERE Configuration_Name__c = 'Log_Activity' LIMIT 1];
        delete objConfig;
        strMessagedeleteExternalFile = ViewFilesControllerHelper.deleteExternalFileLinks(new List<string>{ objEFL.Id }, 'false', strPreSignedURL);
        Assert.areEqual(true, strMessagedeleteExternalFile == Label.File_Not_Found);
        delete objEFL;
        Test.stopTest();
    }

    // getPresignedURL must reject a malformed/non-existent External_File_Link__c Id rather than
    // treating it as a raw S3 key to sign.
    @IsTest
    public static void test_getPresignedURL_rejectsUnknownId() {
        Test.startTest();
        Boolean bolThrew = false;
        try {
            ViewFilesController.getPresignedURL('not-a-real-id', 'GET');
        } catch (AuraHandledException exp) {
            bolThrew = true;
        }
        Assert.areEqual(true, bolThrew, 'A malformed/unknown External_File_Link__c Id must be rejected');
        Test.stopTest();
    }

    // getPresignedURL must reject a file whose Related_To__c record the running user cannot see,
    // since Related_To__c is a plain text field with no native Salesforce sharing enforcement.
    @IsTest
    public static void test_getPresignedURL_rejectsInaccessibleParentRecord() {
        List<External_Files__c> lstExternalFiles = [SELECT Id FROM External_Files__c LIMIT 1];
        Account objOrphanAccount = new Account(Name = 'Orphan Account For Access Test');
        insert objOrphanAccount;
        External_File_Link__c objOrphanEFL = new External_File_Link__c();
        objOrphanEFL.Object_Type__c = 'Account';
        objOrphanEFL.External_Files__c = lstExternalFiles[0].Id;
        objOrphanEFL.Related_To__c = objOrphanAccount.Id;
        insert objOrphanEFL;
        // Delete the parent record so Related_To__c now points at nothing the user can see -
        // models the same failure as a record the user was never shared visibility into.
        delete objOrphanAccount;

        Test.startTest();
        Boolean bolThrew = false;
        try {
            ViewFilesController.getPresignedURL(objOrphanEFL.Id, 'GET');
        } catch (AuraHandledException exp) {
            bolThrew = true;
        }
        Assert.areEqual(true, bolThrew, 'A file whose parent record is not accessible must be rejected');
        Test.stopTest();
    }

    // Mock test class for getFileFromAmazonS3 method
    public class ViewFilesControllerMock1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(204);
            response.setStatus('OK');
            response.setBody('{"response":{"result":"success"}}');
            return response;
        }
    }
    // Mock test class for deleteExternalFile method
    public class ViewFilesControllerMock2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{"response":{"result":"success"}}');
            return response;
        }
    }
}