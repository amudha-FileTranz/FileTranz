/*
 * Purpose : Test class for  PermissionConfigurationsController class
 * Author  : Giri
 */
@IsTest
public class PermissionConfigurationsControllerTest {
    @TestSetup
    static void createTestData() {
        //Create Configuration Test data
        Configuration__c objConfiguration = new Configuration__c();
        objConfiguration.Configuration_Type__c = 'Permission Configuration';
        objConfiguration.Long_Value__c = 'Upload';
        if(Schema.SobjectType.Configuration__c.isCreateable()){
            insert objConfiguration;
        }
        // Ensure the user running these tests is recognized as a FileTranz admin, since
        // PermissionConfigurationsController now gates every method on CommonUtilities.isFileTranzAdmin().
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

    // Test Method to cover the AmazonS3Controller class
    @isTest
    static void permissionConfigurationsControllerTestMethod() {
        Test.startTest();
        // To test getPermissionSets method
        List<PermissionSet> lstPermissionSet = PermissionConfigurationsController.getPermissionSets();
        Assert.isTrue(lstPermissionSet.size() > 0,'True');
        // To test savePermissions method
        Boolean bolSave = PermissionConfigurationsController.savePermissions(new List<String>{lstPermissionSet[0].id}, 'Upload; Download');
        Assert.isTrue(bolSave,'True');
        // To test getPermissionConfigurations method
        List<PermissionConfigurationsController.ConfigurationWrapper> lstConfigurationWrapper = PermissionConfigurationsController.getPermissionConfigurations();
        Assert.isTrue(lstConfigurationWrapper.size() > 0,'True');
        // To test updateConfiguration method
        Boolean bolUpdate = PermissionConfigurationsController.updateConfiguration(lstConfigurationWrapper);
        Assert.isTrue(bolUpdate,'True');
        // To test deleteConfigurations method
        Boolean bolDelete = PermissionConfigurationsController.deleteConfigurations(new List<String>{lstConfigurationWrapper[0].idConfiguration});
        Assert.isTrue(bolDelete,'True');
        Test.stopTest();
    }
    
    @IsTest
    public static void testGetPermissionSetsException() {
        Test.startTest();
        Configuration__c objConfiguration = new Configuration__c();
        objConfiguration.Configuration_Type__c = 'Permission Configuration';
        objConfiguration.Configuration_Name__c = 'InvalidKeyCausingException';
        insert objConfiguration;
        List<PermissionSet> lisResult=new  List<PermissionSet>();
        List<PermissionConfigurationsController.ConfigurationWrapper> lisconfigWrapper=new List<PermissionConfigurationsController.ConfigurationWrapper>();
        try {
            lisResult = PermissionConfigurationsController.getPermissionSets();
            lisconfigWrapper= PermissionConfigurationsController.getPermissionConfigurations();
        } catch (Exception e) {
            lisResult = null;
        }
        System.assertEquals(1, lisconfigWrapper.size(),'Tested');
        System.assertEquals(null, lisResult,'Tested');
        Test.stopTest();
    }
}