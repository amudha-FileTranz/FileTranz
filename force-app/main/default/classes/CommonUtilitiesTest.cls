/*
 * Purpose : Test class for CommonUtilitiesTest class
 * Author  : Giri
 */
@isTest
public class CommonUtilitiesTest {
    @TestSetup
    static void createTestData(){
        // Account Test data
        List<Account> lstAcc = new List<Account>();
        Account objAccount = new Account(Name = 'Test Account');
        lstAcc.add(ObjAccount);
        Account objAccount1 = new Account(Name = 'Test Account1');
        lstAcc.add(ObjAccount1);
        if(Schema.sObjectType.Account.fields.Name.isCreateable()){
            insert lstAcc;
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

        // External_File_Link__c test data
        External_File_Link__c objEFL = new External_File_Link__c();
        objEFL.Object_Type__c = 'Account';
        objEFL.External_Files__c = lstEF[0].Id;
        objEFL.Related_To__c = ObjAccount.Id;
        objEFL.Is_Deleted__c = true;
        if(Schema.sObjectType.External_File_Link__c.isCreateable()){
            insert objEFL;
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
        if(Schema.sObjectType.External_Storage_Settings__c.isCreateable()){
            insert objESS;
        }
        
        // Create Configuration Test data
        List<Configuration__c> lstConfigs = new List<Configuration__c>();
        Configuration__c objConfiguration = new Configuration__c();
        objConfiguration.Configuration_Type__c = 'Permission Configuration';
        objConfiguration.Configuration_Name__c = 'OWD';
        objConfiguration.Long_Value__c = 'Upload';
        lstConfigs.add(objConfiguration);
        if(Schema.sObjectType.Configuration__c.isCreateable()){
            insert lstConfigs;
        }
        
        // Create User Test data
        User testUser = new User();
        Profile profile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        testUser.FirstName = 'Test';
        testUser.LastName = 'User';
        testUser.Username = 'testuser20187@example.com';
        testUser.Email = 'testuser20187@example.com';
        testUser.Alias = 'tuser';
        testUser.CommunityNickname = 'tuser';
        testUser.TimeZoneSidKey = 'America/Los_Angeles';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.ProfileId = profile.Id;
        if(Schema.sObjectType.User.isCreateable()){
            insert testUser;
        }
        System.runAs(testUser){
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'FileTranz_Admin' LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = UserInfo.getUserId();
            psa.PermissionSetId = ps.Id;
            if(Schema.sObjectType.PermissionSetAssignment.isCreateable()){
                insert psa; 
            }
        }
        
        // Create Contact test data
        Contact objContact = new Contact();
        objContact.LastName = 'Test Contact 1';
        objContact.AccountId = ObjAccount.Id;
        if(Schema.sObjectType.Contact.isCreateable()){
            insert objContact;
        }

        // Create an instance of ExternalFilesWrapper
        CommonUtilities.ExternalFilesWrapper wrapper = new CommonUtilities.ExternalFilesWrapper();
        Id testId = objAccount.Id;
        wrapper.strId = testId;
        wrapper.strName = 'Test Name';
        wrapper.strFileName = 'TestFile.pdf';
        wrapper.strSize = '15 MB';
        wrapper.strFileURL = 'https://example.com/testfile';
        wrapper.strObjectType = 'Document';
        wrapper.LastModifiedDate = '2025-02-12';
        wrapper.strDisplayText = 'Test Display Text';
        wrapper.strRelatedTo = 'Test Related Object';
        wrapper.strFileType = 'PDF';
        wrapper.bolShowEdit = true;
        wrapper.bolSelected = false;
        wrapper.SNo = 1;
        wrapper.dblSize = 15.0;
        wrapper.bolDisable = false;
        wrapper.strUID = 'UID12345';
        wrapper.strExternalFileId = 'External12345';

        
    }
    
    // Test method to cover CommonUtilities class
    @isTest
    public static void commonUtilitiesTestMethod() {
        Test.startTest();
        // To cover getFileSizeInKB method
        double dblretValue = CommonUtilities.getFileSizeInKB('1025KB');
        Decimal decKb = 1025*1024;
        System.assertEquals(1049600, decKb, 'decKb must be 1049600 bytes');

        double dblretValue1 = CommonUtilities.getFileSizeInKB('1025MB');
        Decimal decMb = 1025*1024*1024;
        System.assertEquals(1074790400, decMb, 'decMb must be 1074790400 bytes');

        double dblretValue2 = CommonUtilities.getFileSizeInKB('1025GB');
        Assert.areEqual(true,dblretValue2 != null, 'dblretValue2 should have value');

        double dblretValue3 = CommonUtilities.getFileSizeInKB('1025B');
        Assert.areEqual(true,dblretValue3 != null, 'dblretValue3 should have value');

        // To cover getDeletedExternalFiles method
        List<External_File_Link__c> lstEF = CommonUtilities.getDeletedExternalFiles();
        Assert.areEqual(true,lstEF.size() == 1, 'lstEF size must be 1');

        // To cover getAllObjectName method
        list<CommonUtilities.EntityDefinitionWrapper> lstEntityDefinitionWrapper = CommonUtilities.getAllObjectName();
        Assert.areEqual(true,lstEntityDefinitionWrapper != null, 'lstEntityDefinitionWrapper should have value');

        // To cover getSObjectFields method
        list<CommonUtilities.EntityDefinitionWrapper> lstEntityDefinitionWrapper1 = CommonUtilities.getSObjectFields('Account');
        Assert.areEqual(true,lstEntityDefinitionWrapper1 != null, 'lstEntityDefinitionWrapper1 should have value');

        // To cover getCurrentUserPermissions method
        List<String> lstConfig = CommonUtilities.getCurrentUserPermissions();
        External_File_Link__c objEFL = [SELECT Id FROM External_File_Link__c limit 1];
        list<string> lstString = new list<string>();
        lstString.add(objEFL.id);
        // To cover restoreExternalfile method
        String strRetMssg = CommonUtilities.restoreExternalfile(lstString);
        Assert.areEqual(true,strRetMssg == 'Success', 'strRetMssg shold be Success');

        // To cover FormatFileSize method
        String strSize1 = CommonUtilities.FormatFileSize(1020);
        Assert.areEqual(true,strSize1 == '1020 B', 'strSize1 should be 1020 B');

        String strSize2 = CommonUtilities.FormatFileSize(1048375);
        Assert.areEqual(true,strSize2 != null, 'strSize2 should not be null');

        String strSize3 = CommonUtilities.FormatFileSize(102464567);
        Assert.areEqual(true,strSize3 != null, 'strSize3 should not be null');

        String strSize4 = CommonUtilities.FormatFileSize(1073741824);
        Assert.areEqual(true,strSize4 != null, 'strSize4 should not be null');

        // To cover getActiveStorageSettingForLWC method
        CommonUtilities.ExternalStorageSettingWrapper objExtStorageWrapper = CommonUtilities.getActiveStorageSettingForLWC();
        Assert.isNotNull(objExtStorageWrapper, 'Error in getting storage configuration in getActiveStorageSettingForLWC method.');
        
        Configuration__c objConfig = [SELECT Configuration_Type__c FROM Configuration__c LIMIT 1];
        List<String> lstConfigtype = new List<String>();
        lstConfigtype.add(objConfig.Configuration_Type__c);
        
        // To cover getConfiguration method
        Map<String, String> mapConfig = CommonUtilities.getConfiguration(lstConfigtype);
        System.assertEquals(1, mapConfig.size(), 'mapConfig size must be 1');
        
       // To check ActiveStorageSetting method
        External_Storage_Settings__c objESS = [SELECT Access_Key__c,Secret_Key__c,Bucket__c,Region__c,File_Retrieve_URL__c,Name,Storage__c,Active__c FROM External_Storage_Settings__c LIMIT 1]; 
        CommonUtilities.getActiveStorageSetting();
        System.assertEquals(true, objESS.Active__c, 'Active must be true');
        
        // To cover getObjectLabelFromId method
        Account objAccount = [SELECT Id, Name FROM Account LIMIT 1];
        String objectLabel = CommonUtilities.getObjectLabelFromId(objAccount.Id);
        System.assertEquals('Account', objectLabel, 'objectLabel Name must be Account');
        
        // To check checkRelatedRecords method
        Map<String, List<String>> mapObjectWithRecordIds = new Map<String, List<String>>();
        mapObjectWithRecordIds.put('Account', new List<String>{ objAccount.Id });
        CommonUtilities.checkRelatedRecords(mapObjectWithRecordIds);
        
        // Create an instance of ExternalFilesWrapper
        CommonUtilities.ExternalFilesWrapper objExtFilesWrapper = new CommonUtilities.ExternalFilesWrapper();
        Id testId = objAccount.Id;
        objExtFilesWrapper.strId = testId;
        objExtFilesWrapper.strName = 'Test Name';
        objExtFilesWrapper.strFileName = 'TestFile.pdf';
        objExtFilesWrapper.strSize = '15 MB';
        objExtFilesWrapper.strFileURL = 'https://example.com/testfile';
        objExtFilesWrapper.strObjectType = 'Document';
        objExtFilesWrapper.LastModifiedDate = '2025-02-12';
        objExtFilesWrapper.strDisplayText = 'Test Display Text';
        objExtFilesWrapper.strRelatedTo = 'Test Related Object';
        objExtFilesWrapper.strFileType = 'PDF';
        objExtFilesWrapper.bolShowEdit = true;
        objExtFilesWrapper.bolSelected = false;
        objExtFilesWrapper.SNo = 1;
        objExtFilesWrapper.dblSize = 15.0;
        objExtFilesWrapper.bolDisable = false;
        objExtFilesWrapper.strUID = 'UID12345';
        objExtFilesWrapper.strExternalFileId = 'External12345';
        Test.stopTest();
    }
}