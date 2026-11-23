/*
 * Purpose : Test class for StorageConfigurationsController class.
 * Author  : Giri
 */
@isTest
public class StorageConfigurationsControllerTest {
    @TestSetup
    static void createTestData() {
        // Configuration test data
        Configuration__c objConfig = new Configuration__c();
        objConfig.Configuration_Name__c = 'AWS';
        objConfig.Configuration_Type__c = 'Storage Configuration';
        objConfig.Long_Value__c = 'Account';
        if (Schema.SObjectType.Configuration__c.isCreateable()) {
            insert objConfig;
        }
        // External Storage Setting test data
        List<External_Storage_Settings__c> lstExtStorSettings = new List<External_Storage_Settings__c>();
        External_Storage_Settings__c objExtStrgSet = new External_Storage_Settings__c();
        objExtStrgSet.Name = 'AWS';
        objExtStrgSet.Access_Key__c = 'TestAccesskey';
        objExtStrgSet.Secret_Key__c = 'TestSecretKey';
        objExtStrgSet.Region__c = 'TestRegion';
        objExtStrgSet.Bucket__c = 'TestBucket';
        objExtStrgSet.File_Retrieve_URL__c = 'TestURL';
        objExtStrgSet.Active__c = true;
        lstExtStorSettings.add(objExtStrgSet);
        External_Storage_Settings__c objExtStrgSet1 = new External_Storage_Settings__c();
        objExtStrgSet1.Name = 'AWS1';
        objExtStrgSet1.Access_Key__c = 'TestAccesskey';
        objExtStrgSet1.Secret_Key__c = 'TestSecretKey';
        objExtStrgSet1.Region__c = 'TestRegion';
        objExtStrgSet1.Bucket__c = 'TestBucket';
        objExtStrgSet1.File_Retrieve_URL__c = 'TestURL';
        objExtStrgSet1.Active__c = false;
        lstExtStorSettings.add(objExtStrgSet1);
        if (Schema.SObjectType.External_Storage_Settings__c.isCreateable()) {
            insert lstExtStorSettings;
        }
        // Ensure the user running these tests is recognized as a FileTranz admin, since
        // StorageConfigurationsController now gates every method on CommonUtilities.isFileTranzAdmin().
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

    private static User createStandardTestUser(String usernamePrefix) {
        User objUser = new User();
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' WITH USER_MODE LIMIT 1];
        objUser.FirstName = 'Test';
        objUser.LastName = 'User';
        objUser.Username = usernamePrefix + '@example.com';
        objUser.Email = usernamePrefix + '@example.com';
        objUser.Alias = 'tuser';
        objUser.CommunityNickname = usernamePrefix;
        objUser.TimeZoneSidKey = 'America/Los_Angeles';
        objUser.LocaleSidKey = 'en_US';
        objUser.EmailEncodingKey = 'UTF-8';
        objUser.LanguageLocaleKey = 'en_US';
        objUser.ProfileId = objProfile.Id;
        if (Schema.sObjectType.User.isCreateable()) {
            insert objUser;
        }
        return objUser;
    }

    @isTest
    static void nonAdminCannotAccessStorageConfiguration() {
        User objNonAdminUser = createStandardTestUser('filetranznonadmin');
        System.runAs(objNonAdminUser) {
            assignPermissionSetIfMissing(objNonAdminUser.Id, 'FileTranz_User');
        }

        System.runAs(objNonAdminUser) {
            Boolean bolThrew = false;
            try {
                StorageConfigurationsController.getAllStorageConfig();
            } catch (AuraHandledException exp) {
                bolThrew = true;
            }
            Assert.areEqual(true, bolThrew, 'Non-admin user must not be able to read storage configuration');

            bolThrew = false;
            try {
                StorageConfigurationsController.validateConnection(JSON.serialize(new CommonUtilities.ExternalStorageSettingWrapper()));
            } catch (AuraHandledException exp) {
                bolThrew = true;
            }
            Assert.areEqual(true, bolThrew, 'Non-admin user must not be able to validate storage configuration');

            bolThrew = false;
            try {
                StorageConfigurationsController.createUpdateExtStorageSetting(JSON.serialize(new CommonUtilities.ExternalStorageSettingWrapper()), 'Account');
            } catch (AuraHandledException exp) {
                bolThrew = true;
            }
            Assert.areEqual(true, bolThrew, 'Non-admin user must not be able to create or update storage configuration');
        }
    }

    @isTest
    static void storageConfigurationsControllerTestMethod() {
        List<External_Storage_Settings__c> lstExtStrSet = [SELECT id,Name FROM External_Storage_Settings__c WITH USER_MODE];
        Test.startTest();
        List<CommonUtilities.ExternalStorageSettingWrapper> lstExternalStorageSettingWrapper = StorageConfigurationsController.getAllStorageConfig();
        Assert.areEqual(true, lstExternalStorageSettingWrapper != null,'Return List of ExternalStorageSettingWrappe records');
        CommonUtilities.ExternalStorageSettingWrapper objWrap = new CommonUtilities.ExternalStorageSettingWrapper();
        objWrap.strName = 'Test';
        String strMsggSuccess = StorageConfigurationsController.createUpdateExtStorageSetting(JSON.serialize(objWrap),'Account');
        Assert.areEqual(true, strMsggSuccess == 'Successfully Created','Expected string Successfully Created');
        String strMsggException = StorageConfigurationsController.createUpdateExtStorageSetting(JSON.serialize(null),'Account');
        // To cover validateConnection method
        objWrap.strAccKy = String.valueOf(UserInfo.getUserId());
        objWrap.strStKy = String.valueOf(Crypto.getRandomInteger());
        objWrap.strBucket = 'dummyBucket';
        objWrap.strRegion = 'eu-north-1';
        objWrap.strEndPoint = 'example.com';
        objWrap.strActive = true;
        objWrap.strId = 'Test';
        objWrap.strObjects = 'Test';
        String strResponse = StorageConfigurationsController.validateConnection(JSON.serialize(objWrap));
        Assert.areEqual(true, strResponse != null,'Expected Return value Not Equal to Null');
        String strResponse1 = StorageConfigurationsController.validateConnection('null');
        Test.stopTest();
    }
}