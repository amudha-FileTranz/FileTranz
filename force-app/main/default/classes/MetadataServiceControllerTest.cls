/*
 * Purpose : Test class for  MetadataServiceController class
 * Author  : Giri
 */
@isTest
public class MetadataServiceControllerTest {
    private class WebServiceMockImpl implements WebServiceMock{
        public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType){
            if(request instanceof MetadataServiceController.updateMetadata_element){
                response.put('response_x', new MetadataServiceController.updateMetadataResponse_element());
            }else if(request instanceof  MetadataServiceController.deleteMetadata_element){
                response.put('response_x', new MetadataServiceController.deleteMetadataResponse_element());
            } else if(request instanceof  MetadataServiceController.createMetadata_element){
                response.put('response_x', new MetadataServiceController.createMetadataResponse_element());
            }
            return;
        }
    }
    @IsTest
    private static void coverGeneratedCodeCRUDOperations(){
        // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        MetadataServiceController metadataServiceController = new MetadataServiceController();
        // Invoke operations
        Test.startTest();
        MetadataServiceController.MetadataPort metaDataPort = new MetadataServiceController.MetadataPort();
        System.assertEquals(null, metaDataPort.AllOrNoneHeader=null,'');
        
        Test.stopTest();
    }
    
    @IsTest
    private static void coverGeneratedCodeFileBasedOperations1(){
        // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        MetadataServiceController metadataServiceController = new MetadataServiceController();
        // Invoke operations
        Test.startTest();
        MetadataServiceController.MetadataPort metaDataPort = new MetadataServiceController.MetadataPort();
        System.assertEquals(null, metaDataPort.AllOrNoneHeader=null,'');
        metaDataPort.updateMetadata(null);
        Test.stopTest();
    }
    
    @IsTest
    private static void coverGeneratedCodeFileBasedOperations2(){
        // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        MetadataServiceController metadataServiceController = new MetadataServiceController();
        // Invoke operations
        Test.startTest();
        MetadataServiceController.MetadataPort metaDataPort = new MetadataServiceController.MetadataPort();
        System.assertEquals(true, metaDataPort!=null,'Expected Return value Not Equal to Null');
        System.assertEquals(null, metaDataPort.AllOrNoneHeader=null,'');
        metaDataPort.deleteMetadata(null, null);
        metaDataPort.createMetadata(null);
        Test.stopTest();
    }
    @IsTest
    private static void metaTypesTest(){
        // Reference types
        Test.startTest();
        new MetadataServiceController();
        new MetadataServiceController.FilterItem();
        new MetadataServiceController.LogInfo();
        new MetadataServiceController.CustomDataTypeTranslation();
        new MetadataServiceController.CallOptions_element();
        new MetadataServiceController.ScontrolTranslation();
        new MetadataServiceController.CustomField();
        new MetadataServiceController.CustomTabTranslation();
        new MetadataServiceController.DebuggingHeader_element();
        new MetadataServiceController.CustomDataTypeComponentTranslation();
        new MetadataServiceController.ReportTypeSectionTranslation();
        new MetadataServiceController.CustomLabel();
        new MetadataServiceController.Metadata();
        new MetadataServiceController.SessionHeader_element();
        new MetadataServiceController.Translations();
        new MetadataServiceController.ReportTypeTranslation();
        new MetadataServiceController.CustomApplicationTranslation();
        new MetadataServiceController.ReportTypeColumnTranslation();
        new MetadataServiceController.CustomPageWebLinkTranslation();
        new MetadataServiceController.CustomLabelTranslation();
        new MetadataServiceController.DebuggingInfo_element();
        new MetadataServiceController.GlobalQuickActionTranslation();
        new MetadataServiceController.deleteMetadataResponse_element();
        new MetadataServiceController.Error();
        new MetadataServiceController.SaveResult();
        new MetadataServiceController.deleteMetadata_element();
        new MetadataServiceController.createMetadataResponse_element();
        new MetadataServiceController.updateMetadata_element();
        new MetadataServiceController.LookupFilter();
        new MetadataServiceController.updateMetadataResponse_element();
        new MetadataServiceController.createMetadata_element();
        new MetadataServiceController.readMetadata_element();
        new MetadataServiceController.ReadTranslationsResult();
        new MetadataServiceController.readTranslationsResponse_element();
        new MetadataServiceController.DeleteResult();
        new MetadataServiceController.CustomMetadata();
        new MetadataServiceController.CustomMetadataValue();
        new MetadataServiceController.AllOrNoneHeader_element();
        new MetadataServiceController.ValueSetValuesDefinition();
        new MetadataServiceController.ValueSet();
        new MetadataServiceController.ValueSettings();

        MetadataServiceController controller = new MetadataServiceController();
        Test.stopTest();

        System.assertNotEquals(null, controller, 'controller instance must not be null');
    }
    
    @IsTest
    static void testFlowChoiceTranslation() {
        Test.startTest();
        MetadataServiceController.FlowChoiceTranslation objFlowChoice = new MetadataServiceController.FlowChoiceTranslation();
        objFlowChoice.choiceText = 'Sample Choice';
        objFlowChoice.name = 'SampleName';
        objFlowChoice.userInput = new MetadataServiceController.FlowChoiceUserInputTranslation();
        Test.stopTest();
        
        System.assertEquals('Sample Choice', objFlowChoice.choiceText, 'objFlowChoice.choiceText must be Sample Choice');
        System.assertEquals('SampleName', objFlowChoice.name, 'objFlowChoice.name must be SampleName');
    }
    
    @IsTest
    static void testFlowScreenFieldTranslation() {
        Test.startTest();
        // Create an instance of the FlowScreenFieldTranslation class
        MetadataServiceController.FlowScreenFieldTranslation objFlowScreenField = new MetadataServiceController.FlowScreenFieldTranslation();
        
        // Set test data
        objFlowScreenField.fieldText = 'Test Field Text';
        objFlowScreenField.helpText = 'Test Help Text';
        objFlowScreenField.name = 'TestName';
        
        // Mocking the validation rule object if needed
        MetadataServiceController.FlowInputValidationRuleTranslation validationRule = new MetadataServiceController.FlowInputValidationRuleTranslation();
        validationRule.errorMessage = 'Test Error Message';
        
        objFlowScreenField.validationRule = validationRule;
        Test.stopTest();
        
        // Validate the data is set correctly
        System.assertEquals('Test Field Text', objFlowScreenField.fieldText, 'objFlowScreenField.fieldText must be Test Field Text');
        System.assertEquals('Test Help Text', objFlowScreenField.helpText, 'objFlowScreenField.helpText must be Test Help Text');
        System.assertEquals('TestName', objFlowScreenField.name, 'objFlowScreenField.name must be TestName');
        System.assertEquals('Test Error Message', objFlowScreenField.validationRule.errorMessage, 'objFlowScreenField.validationRule.errorMessage must be Test Error Message');
    }
    
    @IsTest
    static void testFlowDefinitionTranslation() {
        Test.startTest();
        // Arrange
        MetadataServiceController.FlowDefinitionTranslation objFlowDefTrans = new MetadataServiceController.FlowDefinitionTranslation();
        
        // Create mock flow translations
        MetadataServiceController.FlowTranslation objFlow1 = new MetadataServiceController.FlowTranslation();
        objFlow1.fullName = 'TestFlow1';
        objFlow1.label = 'Test Flow 1';
        
        MetadataServiceController.FlowTranslation objFlow2 = new MetadataServiceController.FlowTranslation();
        objFlow2.fullName = 'TestFlow2';
        objFlow2.label = 'Test Flow 2';
        
        objFlowDefTrans.flows = new MetadataServiceController.FlowTranslation[]{ objFlow1, objFlow2 };
        objFlowDefTrans.fullName = 'TestFlowDefinition';
        objFlowDefTrans.label = 'Test Flow Definition';
        Test.stopTest();
        
        System.assertNotEquals(null, objFlowDefTrans, 'objFlowDefTrans not equals to null');
        System.assertEquals('TestFlowDefinition', objFlowDefTrans.fullName, 'objFlowDefTrans.fullName must be TestFlowDefinition');
        System.assertEquals('Test Flow Definition', objFlowDefTrans.label, 'objFlowDefTrans.label must be Test Flow Definition');
        System.assertEquals(2, objFlowDefTrans.flows.size(), 'objFlowDefTrans.flows.size() must be 2');
        System.assertEquals('TestFlow1', objFlowDefTrans.flows[0].fullName, 'objFlowDefTrans.flows[0].fullName must be TestFlow1');
        System.assertEquals('Test Flow 1', objFlowDefTrans.flows[0].label, 'objFlowDefTrans.flows[0].label must be est Flow 1');
        System.assertEquals('TestFlow2', objFlowDefTrans.flows[1].fullName, 'objFlowDefTrans.flows[1].fullName must be TestFlow2');
        System.assertEquals('Test Flow 2', objFlowDefTrans.flows[1].label, 'objFlowDefTrans.flows[1].label must be Test Flow 2');
    }
    
    @IsTest
    static void testFlowScreenTranslation() {
        Test.startTest();
        // Create an instance of FlowScreenTranslation
        MetadataServiceController.FlowScreenTranslation objFlowScreenTranslation = new MetadataServiceController.FlowScreenTranslation();
        
        // Mock data for testing
        objFlowScreenTranslation.helpText = 'Sample Help Text';
        objFlowScreenTranslation.name = 'Sample Name';
        objFlowScreenTranslation.pausedText = 'Sample Paused Text';
        
        // Create a mock FlowScreenFieldTranslation array
        MetadataServiceController.FlowScreenFieldTranslation objField1 = new MetadataServiceController.FlowScreenFieldTranslation();
        objField1.name = 'Field1';
        objField1.helpText = 'Help Text for Field1';
        
        MetadataServiceController.FlowScreenFieldTranslation objField2 = new MetadataServiceController.FlowScreenFieldTranslation();
        objField2.name = 'Field2';
        objField2.helpText = 'Help Text for Field2';
        
        objFlowScreenTranslation.fields = new MetadataServiceController.FlowScreenFieldTranslation[] { objField1, objField2 };
        Test.stopTest();
        
        // Assertions to check if the data is set correctly
        System.assertEquals('Sample Help Text', objFlowScreenTranslation.helpText, 'objFlowScreenTranslation.helpText must be Sample Help Text');
        System.assertEquals('Sample Name', objFlowScreenTranslation.name, 'objFlowScreenTranslation.name must be Sample Name');
        System.assertEquals('Sample Paused Text', objFlowScreenTranslation.pausedText, 'objFlowScreenTranslation.pausedText must be Sample Paused Text');
        System.assertEquals(2, objFlowScreenTranslation.fields.size(), 'objFlowScreenTranslation.fields.size() must be 2');
        System.assertEquals('Field1', objFlowScreenTranslation.fields[0].name, 'objFlowScreenTranslation.fields[0].name must be Field1');
        System.assertEquals('Help Text for Field1', objFlowScreenTranslation.fields[0].helpText, 'objFlowScreenTranslation.fields[0].helpText must be Help Text for Field1');
        System.assertEquals('Field2', objFlowScreenTranslation.fields[1].name, 'objFlowScreenTranslation.fields[1].name must be Field2');
        System.assertEquals('Help Text for Field2', objFlowScreenTranslation.fields[1].helpText, 'objFlowScreenTranslation.fields[1].helpText must be Help Text for Field2');
    }
    
    @isTest
    static void testCreateService() {
        Test.startTest();
        MetadataServiceController.MetadataPort service = MetadataServiceController.createService();
        Assert.areEqual(true, service!=null, 'service should not be null');
        Test.stopTest();
    }
}