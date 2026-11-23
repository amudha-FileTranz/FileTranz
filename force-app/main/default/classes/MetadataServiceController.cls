/*
 * Purpose : To controll the custom label creation actions
 * Author  : Giri
 */
public with sharing class MetadataServiceController {
    public static String strSoapUrl = 'http://soap.sforce.com/2006/04/metadata';

    public virtual class Metadata {
        public String fullName;
    }
    public class MetadataPort {
        public String strEndPointUrl = URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/42.0';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        public MetadataServiceController.SessionHeader_element SessionHeader;
        public MetadataServiceController.DebuggingInfo_element DebuggingInfo;
        public MetadataServiceController.DebuggingHeader_element DebuggingHeader;
        public MetadataServiceController.CallOptions_element CallOptions;
        public MetadataServiceController.AllOrNoneHeader_element AllOrNoneHeader;
        private String SessionHeader_hns = 'SessionHeader=http://soap.sforce.com/2006/04/metadata';
        private String DebuggingInfo_hns = 'DebuggingInfo=http://soap.sforce.com/2006/04/metadata';
        private String DebuggingHeader_hns = 'DebuggingHeader=http://soap.sforce.com/2006/04/metadata';
        private String CallOptions_hns = 'CallOptions=http://soap.sforce.com/2006/04/metadata';
        private String AllOrNoneHeader_hns = 'AllOrNoneHeader=http://soap.sforce.com/2006/04/metadata';
        private String[] ns_map_type_info = new String[]{strSoapUrl, 'MetadataServiceController'};

        public MetadataServiceController.DeleteResult[] deleteMetadata(String type_x,String[] fullNames) {
            MetadataServiceController.deleteMetadata_element request_x = new MetadataServiceController.deleteMetadata_element();
            request_x.type_x = type_x;
            request_x.fullNames = fullNames;
            MetadataServiceController.deleteMetadataResponse_element response_x;
            Map<String, MetadataServiceController.deleteMetadataResponse_element> response_map_x = new Map<String, MetadataServiceController.deleteMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{strEndPointUrl,
              '',
              strSoapUrl,
              'deleteMetadata',
              strSoapUrl,
              'deleteMetadataResponse',
              'MetadataServiceController.deleteMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }
        
        public MetadataServiceController.SaveResult[] updateMetadata(MetadataServiceController.Metadata[] metadata) {
            MetadataServiceController.updateMetadata_element request_x = new MetadataServiceController.updateMetadata_element();
            request_x.metadata = metadata;
            MetadataServiceController.updateMetadataResponse_element response_x;
            Map<String, MetadataServiceController.updateMetadataResponse_element> response_map_x = new Map<String, MetadataServiceController.updateMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{strEndPointUrl,
              '',
              strSoapUrl,
              'updateMetadata',
              strSoapUrl,
              'updateMetadataResponse',
              'MetadataServiceController.updateMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }
        public MetadataServiceController.SaveResult[] createMetadata(MetadataServiceController.Metadata[] metadata) {
            MetadataServiceController.createMetadata_element request_x = new MetadataServiceController.createMetadata_element();
            request_x.metadata = metadata;
            MetadataServiceController.createMetadataResponse_element response_x;
            Map<String, MetadataServiceController.createMetadataResponse_element> response_map_x = new Map<String, MetadataServiceController.createMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            System.debug('response:'+ response_x);
            System.debug('resp Map:'+ response_map_x);
            System.debug('Request Metadata:' + request_x.metadata);
            System.debug('Request:' + request_x);
            try{
                WebServiceCallout.invoke(
                    this,
                request_x,
                response_map_x,
                new String[]{strEndPointUrl,
                    '',
                    strSoapUrl,
                    'createMetadata',
                    strSoapUrl,
                    'createMetadataResponse',
                'MetadataServiceController.createMetadataResponse_element'}
                );
            }catch(Exception e){
                System.debug('Callout Exception: ' + e.getMessage());
            }
            response_x = response_map_x.get('response_x');
            System.debug('response_x.result::'+ response_x.result);
            return response_x.result;
        }
        public MetadataServiceController.IReadResult readMetadata(String type_x,String[] fullNames) {
            MetadataServiceController.readMetadata_element request_x = new MetadataServiceController.readMetadata_element();
            request_x.type_x = type_x;
            request_x.fullNames = fullNames;
            MetadataServiceController.IReadResponseElement response_x;
            Map<String, MetadataServiceController.IReadResponseElement> response_map_x = new Map<String, MetadataServiceController.IReadResponseElement>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{strEndPointUrl,
              '',
              strSoapUrl,
              'readMetadata',
              strSoapUrl,
              'readMetadataResponse',
              'MetadataServiceController.read' + type_x + 'Response_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.getResult();
        }
    }
    public class SessionHeader_element {
        public String sessionId;
        private String[] sessionId_type_info = new String[]{'sessionId',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'sessionId'};
    }
    public class DebuggingInfo_element {
        public String debugLog;
        private String[] debugLog_type_info = new String[]{'debugLog',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'debugLog'};
    }
    public class DebuggingHeader_element {
        public MetadataServiceController.LogInfo[] categories;
        public String debugLevel;
        private String[] categories_type_info = new String[]{'categories',strSoapUrl,null,'0','-1','false'};
        private String[] debugLevel_type_info = new String[]{'debugLevel',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'categories','debugLevel'};
    }

    public class LogInfo {
        public String category;
        public String level;
        private String[] category_type_info = new String[]{'category',strSoapUrl,null,'1','1','false'};
        private String[] level_type_info = new String[]{'level',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'category','level'};
    }

    public class CallOptions_element {
        public String client;
        private String[] client_type_info = new String[]{'client',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'client'};
    }

    public class AllOrNoneHeader_element {
        public Boolean allOrNone;
        private String[] allOrNone_type_info = new String[]{'allOrNone',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'allOrNone'};
    }

    public class deleteMetadata_element {
        public String type_x;
        public String[] fullNames;
        private String[] type_x_type_info = new String[]{'type',strSoapUrl,null,'1','1','false'};
        private String[] fullNames_type_info = new String[]{'fullNames',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'type_x','fullNames'};
    }

    public class deleteMetadataResponse_element {
        public MetadataServiceController.DeleteResult[] result;
        private String[] result_type_info = new String[]{'result',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    public class DeleteResult {
        public MetadataServiceController.Error[] errors;
        public String fullName;
        public Boolean success;
        private String[] errors_type_info = new String[]{'errors',strSoapUrl,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',strSoapUrl,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'errors','fullName','success'};
    }

    public class Error {
        public MetadataServiceController.ExtendedErrorDetails[] extendedErrorDetails;
        public String[] fields;
        public String message;
        public String statusCode;
        private String[] extendedErrorDetails_type_info = new String[]{'extendedErrorDetails',strSoapUrl,null,'0','-1','false'};
        private String[] fields_type_info = new String[]{'fields',strSoapUrl,null,'0','-1','false'};
        private String[] message_type_info = new String[]{'message',strSoapUrl,null,'1','1','false'};
        private String[] statusCode_type_info = new String[]{'statusCode',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'extendedErrorDetails','fields','message','statusCode'};
    }

    public class ExtendedErrorDetails {
        public String extendedErrorCode;
        private String[] extendedErrorCode_type_info = new String[]{'extendedErrorCode',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'extendedErrorCode'};
    }

    public class updateMetadata_element {
        public MetadataServiceController.Metadata[] metadata;
        private String[] metadata_type_info = new String[]{'metadata',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'metadata'};
    }
    public class updateMetadataResponse_element {
        public MetadataServiceController.SaveResult[] result;
        private String[] result_type_info = new String[]{'result',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    public class SaveResult {
        public MetadataServiceController.Error[] errors;
        public String fullName;
        public Boolean success;
        private String[] errors_type_info = new String[]{'errors',strSoapUrl,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',strSoapUrl,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'errors','fullName','success'};
    }

    public class createMetadata_element {
        public MetadataServiceController.Metadata[] metadata;
        private String[] metadata_type_info = new String[]{'metadata',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'metadata'};
    }

    public class createMetadataResponse_element {
        public MetadataServiceController.SaveResult[] result;
        private String[] result_type_info = new String[]{'result',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    public class readMetadata_element {
        public String type_x;
        public String[] fullNames;
        private String[] type_x_type_info = new String[]{'type',strSoapUrl,null,'1','1','false'};
        private String[] fullNames_type_info = new String[]{'fullNames',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'type_x','fullNames'};
    }

    public interface IReadResponseElement {
        IReadResult getResult();
    }

    public interface IReadResult {
        MetadataServiceController.Metadata[] getRecords();
    }

    public static MetadataServiceController.MetadataPort createService(){ 
		MetadataServiceController.MetadataPort service = new MetadataServiceController.MetadataPort();
		service.SessionHeader = new MetadataServiceController.SessionHeader_element();
        String strSessionId = SessionIdController.getSessionIdFromVFPage(Page.SessionId);
		service.SessionHeader.sessionId = strSessionId;
		return service;		
	}

    public class Translations extends Metadata {
        public String type = 'Translations';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',strSoapUrl,null,'0','1','false'};
        public MetadataServiceController.CustomApplicationTranslation[] customApplications;
        public MetadataServiceController.CustomDataTypeTranslation[] customDataTypeTranslations;
        public MetadataServiceController.CustomLabelTranslation[] customLabels;
        public MetadataServiceController.CustomPageWebLinkTranslation[] customPageWebLinks;
        public MetadataServiceController.CustomTabTranslation[] customTabs;
        public MetadataServiceController.FlowDefinitionTranslation[] flowDefinitions;
        public MetadataServiceController.GlobalQuickActionTranslation[] quickActions;
        public MetadataServiceController.ReportTypeTranslation[] reportTypes;
        public MetadataServiceController.ScontrolTranslation[] scontrols;
        private String[] customApplications_type_info = new String[]{'customApplications',strSoapUrl,null,'0','-1','false'};
        private String[] customDataTypeTranslations_type_info = new String[]{'customDataTypeTranslations',strSoapUrl,null,'0','-1','false'};
        private String[] customLabels_type_info = new String[]{'customLabels',strSoapUrl,null,'0','-1','false'};
        private String[] customPageWebLinks_type_info = new String[]{'customPageWebLinks',strSoapUrl,null,'0','-1','false'};
        private String[] customTabs_type_info = new String[]{'customTabs',strSoapUrl,null,'0','-1','false'};
        private String[] flowDefinitions_type_info = new String[]{'flowDefinitions',strSoapUrl,null,'0','-1','false'};
        private String[] quickActions_type_info = new String[]{'quickActions',strSoapUrl,null,'0','-1','false'};
        private String[] reportTypes_type_info = new String[]{'reportTypes',strSoapUrl,null,'0','-1','false'};
        private String[] scontrols_type_info = new String[]{'scontrols',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'customApplications','customDataTypeTranslations','customLabels','customPageWebLinks','customTabs','flowDefinitions','quickActions','reportTypes','scontrols'};
    }

    public class CustomApplicationTranslation {
        public String label;
        public String name;
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'1','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'label','name'};
    }

    public class CustomDataTypeTranslation {
        public MetadataServiceController.CustomDataTypeComponentTranslation[] components;
        public String customDataTypeName;
        public String description;
        public String label;
        private String[] components_type_info = new String[]{'components',strSoapUrl,null,'0','-1','false'};
        private String[] customDataTypeName_type_info = new String[]{'customDataTypeName',strSoapUrl,null,'1','1','false'};
        private String[] description_type_info = new String[]{'description',strSoapUrl,null,'0','1','false'};
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'components','customDataTypeName','description','label'};
    }

    public class CustomDataTypeComponentTranslation {
        public String developerSuffix;
        public String label;
        private String[] developerSuffix_type_info = new String[]{'developerSuffix',strSoapUrl,null,'1','1','false'};
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'developerSuffix','label'};
    }

    public class CustomLabelTranslation {
        public String label;
        public String name;
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'1','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'label','name'};
    }

    public class CustomPageWebLinkTranslation {
        public String label;
        public String name;
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'1','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'label','name'};
    }

    public class CustomTabTranslation {
        public String label;
        public String name;
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'1','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'label','name'};
    }

    public class FlowDefinitionTranslation {
        public MetadataServiceController.FlowTranslation[] flows;
        public String fullName;
        public String label;
        private String[] flows_type_info = new String[]{'flows',strSoapUrl,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',strSoapUrl,null,'1','1','false'};
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'flows','fullName','label'};
    }

    public class FlowTranslation {
        public MetadataServiceController.FlowChoiceTranslation[] choices;
        public String fullName;
        public String label;
        public MetadataServiceController.FlowScreenTranslation[] screens;
        private String[] choices_type_info = new String[]{'choices',strSoapUrl,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',strSoapUrl,null,'1','1','false'};
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'0','1','false'};
        private String[] screens_type_info = new String[]{'screens',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'choices','fullName','label','screens'};
    }

    public class FlowScreenTranslation {
        public MetadataServiceController.FlowScreenFieldTranslation[] fields;
        public String helpText;
        public String name;
        public String pausedText;
        private String[] fields_type_info = new String[]{'fields',strSoapUrl,null,'0','-1','false'};
        private String[] helpText_type_info = new String[]{'helpText',strSoapUrl,null,'0','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] pausedText_type_info = new String[]{'pausedText',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'fields','helpText','name','pausedText'};
    }
    public class FlowScreenFieldTranslation {
        public String fieldText;
        public String helpText;
        public String name;
        public MetadataServiceController.FlowInputValidationRuleTranslation validationRule;
        private String[] fieldText_type_info = new String[]{'fieldText',strSoapUrl,null,'0','1','false'};
        private String[] helpText_type_info = new String[]{'helpText',strSoapUrl,null,'0','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] validationRule_type_info = new String[]{'validationRule',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'fieldText','helpText','name','validationRule'};
    }
    public class FlowInputValidationRuleTranslation {
        public String errorMessage;
        private String[] errorMessage_type_info = new String[]{'errorMessage',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'errorMessage'};
    }
    public class FlowChoiceTranslation {
        public String choiceText;
        public String name;
        public MetadataServiceController.FlowChoiceUserInputTranslation userInput;
        private String[] choiceText_type_info = new String[]{'choiceText',strSoapUrl,null,'0','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] userInput_type_info = new String[]{'userInput',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'choiceText','name','userInput'};
    }

    public class FlowChoiceUserInputTranslation {
        public String promptText;
        public MetadataServiceController.FlowInputValidationRuleTranslation validationRule;
        private String[] promptText_type_info = new String[]{'promptText',strSoapUrl,null,'0','1','false'};
        private String[] validationRule_type_info = new String[]{'validationRule',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'promptText','validationRule'};
    }

    public class GlobalQuickActionTranslation {
        public String label;
        public String name;
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'1','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'label','name'};
    }

    public class ReportTypeTranslation {
        public String description;
        public String label;
        public String name;
        public MetadataServiceController.ReportTypeSectionTranslation[] sections;
        private String[] description_type_info = new String[]{'description',strSoapUrl,null,'0','1','false'};
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'0','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] sections_type_info = new String[]{'sections',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'description','label','name','sections'};
    }

    public class ReportTypeSectionTranslation {
        public MetadataServiceController.ReportTypeColumnTranslation[] columns;
        public String label;
        public String name;
        private String[] columns_type_info = new String[]{'columns',strSoapUrl,null,'0','-1','false'};
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'0','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'columns','label','name'};
    }

    public class ReportTypeColumnTranslation {
        public String label;
        public String name;
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'1','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'label','name'};
    }

    public class ScontrolTranslation {
        public String label;
        public String name;
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'1','1','false'};
        private String[] name_type_info = new String[]{'name',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'label','name'};
    }

    public class CustomMetadata extends Metadata {
        public String type = 'CustomMetadata';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',strSoapUrl,null,'0','1','false'};
        public String description;
        public String label;
        public Boolean protected_x;
        public MetadataServiceController.CustomMetadataValue[] values;
        private String[] description_type_info = new String[]{'description',strSoapUrl,null,'0','1','false'};
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'0','1','false'};
        private String[] protected_x_type_info = new String[]{'protected',strSoapUrl,null,'0','1','false'};
        private String[] values_type_info = new String[]{'values',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'description','label','protected_x','values'};
    }

    public class CustomMetadataValue {
        public String field;
        public String value;
        private String[] field_type_info = new String[]{'field',strSoapUrl,null,'1','1','false'};
        private String[] value_type_info = new String[]{'value',strSoapUrl,null,'1','1','true'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'field','value'};
    }

    public class CustomField extends Metadata {
        public String type = 'CustomField';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',strSoapUrl,null,'0','1','false'};
        public String businessOwnerGroup;
        public String businessOwnerUser;
        public String businessStatus;
        public Boolean caseSensitive;
        public String customDataType;
        public String defaultValue;
        public String deleteConstraint;
        public Boolean deprecated;
        public String description;
        public String displayFormat;
        public Boolean displayLocationInDecimal;
        public Boolean encrypted;
        public Boolean escapeMarkup;
        public String externalDeveloperName;
        public Boolean externalId;
        public String fieldManageability;
        public String formula;
        public String formulaTreatBlanksAs;
        public String inlineHelpText;
        public Boolean isConvertLeadDisabled;
        public Boolean isFilteringDisabled;
        public Boolean isNameField;
        public Boolean isSortingDisabled;
        public String label;
        public Integer length;
        public MetadataServiceController.LookupFilter lookupFilter;
        public String maskChar;
        public String maskType;
        public String metadataRelationshipControllingField;
        public Boolean populateExistingRows;
        public Integer precision;
        public String referenceTargetField;
        public String referenceTo;
        public String relationshipLabel;
        public String relationshipName;
        public Integer relationshipOrder;
        public Boolean reparentableMasterDetail;
        public Boolean required;
        public Boolean restrictedAdminField;
        public Integer scale;
        public String securityClassification;
        public Integer startingNumber;
        public Boolean stripMarkup;
        public String summarizedField;
        public MetadataServiceController.FilterItem[] summaryFilterItems;
        public String summaryForeignKey;
        public String summaryOperation;
        public Boolean trackFeedHistory;
        public Boolean trackHistory;
        public Boolean trackTrending;
        public String type_x;
        public Boolean unique;
        public MetadataServiceController.ValueSet valueSet;
        public Integer visibleLines;
        public Boolean writeRequiresMasterRead;
        private String[] businessOwnerGroup_type_info = new String[]{'businessOwnerGroup',strSoapUrl,null,'0','1','false'};
        private String[] businessOwnerUser_type_info = new String[]{'businessOwnerUser',strSoapUrl,null,'0','1','false'};
        private String[] businessStatus_type_info = new String[]{'businessStatus',strSoapUrl,null,'0','1','false'};
        private String[] caseSensitive_type_info = new String[]{'caseSensitive',strSoapUrl,null,'0','1','false'};
        private String[] customDataType_type_info = new String[]{'customDataType',strSoapUrl,null,'0','1','false'};
        private String[] defaultValue_type_info = new String[]{'defaultValue',strSoapUrl,null,'0','1','false'};
        private String[] deleteConstraint_type_info = new String[]{'deleteConstraint',strSoapUrl,null,'0','1','false'};
        private String[] deprecated_type_info = new String[]{'deprecated',strSoapUrl,null,'0','1','false'};
        private String[] description_type_info = new String[]{'description',strSoapUrl,null,'0','1','false'};
        private String[] displayFormat_type_info = new String[]{'displayFormat',strSoapUrl,null,'0','1','false'};
        private String[] displayLocationInDecimal_type_info = new String[]{'displayLocationInDecimal',strSoapUrl,null,'0','1','false'};
        private String[] encrypted_type_info = new String[]{'encrypted',strSoapUrl,null,'0','1','false'};
        private String[] escapeMarkup_type_info = new String[]{'escapeMarkup',strSoapUrl,null,'0','1','false'};
        private String[] externalDeveloperName_type_info = new String[]{'externalDeveloperName',strSoapUrl,null,'0','1','false'};
        private String[] externalId_type_info = new String[]{'externalId',strSoapUrl,null,'0','1','false'};
        private String[] fieldManageability_type_info = new String[]{'fieldManageability',strSoapUrl,null,'0','1','false'};
        private String[] formula_type_info = new String[]{'formula',strSoapUrl,null,'0','1','false'};
        private String[] formulaTreatBlanksAs_type_info = new String[]{'formulaTreatBlanksAs',strSoapUrl,null,'0','1','false'};
        private String[] inlineHelpText_type_info = new String[]{'inlineHelpText',strSoapUrl,null,'0','1','false'};
        private String[] isConvertLeadDisabled_type_info = new String[]{'isConvertLeadDisabled',strSoapUrl,null,'0','1','false'};
        private String[] isFilteringDisabled_type_info = new String[]{'isFilteringDisabled',strSoapUrl,null,'0','1','false'};
        private String[] isNameField_type_info = new String[]{'isNameField',strSoapUrl,null,'0','1','false'};
        private String[] isSortingDisabled_type_info = new String[]{'isSortingDisabled',strSoapUrl,null,'0','1','false'};
        private String[] label_type_info = new String[]{'label',strSoapUrl,null,'0','1','false'};
        private String[] length_type_info = new String[]{'length',strSoapUrl,null,'0','1','false'};
        private String[] lookupFilter_type_info = new String[]{'lookupFilter',strSoapUrl,null,'0','1','false'};
        private String[] maskChar_type_info = new String[]{'maskChar',strSoapUrl,null,'0','1','false'};
        private String[] maskType_type_info = new String[]{'maskType',strSoapUrl,null,'0','1','false'};
        private String[] metadataRelationshipControllingField_type_info = new String[]{'metadataRelationshipControllingField',strSoapUrl,null,'0','1','false'};
        private String[] populateExistingRows_type_info = new String[]{'populateExistingRows',strSoapUrl,null,'0','1','false'};
        private String[] precision_type_info = new String[]{'precision',strSoapUrl,null,'0','1','false'};
        private String[] referenceTargetField_type_info = new String[]{'referenceTargetField',strSoapUrl,null,'0','1','false'};
        private String[] referenceTo_type_info = new String[]{'referenceTo',strSoapUrl,null,'0','1','false'};
        private String[] relationshipLabel_type_info = new String[]{'relationshipLabel',strSoapUrl,null,'0','1','false'};
        private String[] relationshipName_type_info = new String[]{'relationshipName',strSoapUrl,null,'0','1','false'};
        private String[] relationshipOrder_type_info = new String[]{'relationshipOrder',strSoapUrl,null,'0','1','false'};
        private String[] reparentableMasterDetail_type_info = new String[]{'reparentableMasterDetail',strSoapUrl,null,'0','1','false'};
        private String[] required_type_info = new String[]{'required',strSoapUrl,null,'0','1','false'};
        private String[] restrictedAdminField_type_info = new String[]{'restrictedAdminField',strSoapUrl,null,'0','1','false'};
        private String[] scale_type_info = new String[]{'scale',strSoapUrl,null,'0','1','false'};
        private String[] securityClassification_type_info = new String[]{'securityClassification',strSoapUrl,null,'0','1','false'};
        private String[] startingNumber_type_info = new String[]{'startingNumber',strSoapUrl,null,'0','1','false'};
        private String[] stripMarkup_type_info = new String[]{'stripMarkup',strSoapUrl,null,'0','1','false'};
        private String[] summarizedField_type_info = new String[]{'summarizedField',strSoapUrl,null,'0','1','false'};
        private String[] summaryFilterItems_type_info = new String[]{'summaryFilterItems',strSoapUrl,null,'0','-1','false'};
        private String[] summaryForeignKey_type_info = new String[]{'summaryForeignKey',strSoapUrl,null,'0','1','false'};
        private String[] summaryOperation_type_info = new String[]{'summaryOperation',strSoapUrl,null,'0','1','false'};
        private String[] trackFeedHistory_type_info = new String[]{'trackFeedHistory',strSoapUrl,null,'0','1','false'};
        private String[] trackHistory_type_info = new String[]{'trackHistory',strSoapUrl,null,'0','1','false'};
        private String[] trackTrending_type_info = new String[]{'trackTrending',strSoapUrl,null,'0','1','false'};
        private String[] type_x_type_info = new String[]{'type',strSoapUrl,null,'0','1','false'};
        private String[] unique_type_info = new String[]{'unique',strSoapUrl,null,'0','1','false'};
        private String[] valueSet_type_info = new String[]{'valueSet',strSoapUrl,null,'0','1','false'};
        private String[] visibleLines_type_info = new String[]{'visibleLines',strSoapUrl,null,'0','1','false'};
        private String[] writeRequiresMasterRead_type_info = new String[]{'writeRequiresMasterRead',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'businessOwnerGroup','businessOwnerUser','businessStatus','caseSensitive','customDataType','defaultValue','deleteConstraint','deprecated','description','displayFormat','displayLocationInDecimal','encrypted','escapeMarkup','externalDeveloperName','externalId','fieldManageability','formula','formulaTreatBlanksAs','inlineHelpText','isConvertLeadDisabled','isFilteringDisabled','isNameField','isSortingDisabled','label','length','lookupFilter','maskChar','maskType','metadataRelationshipControllingField','populateExistingRows','precision','referenceTargetField','referenceTo','relationshipLabel','relationshipName','relationshipOrder','reparentableMasterDetail','required','restrictedAdminField','scale','securityClassification','startingNumber','stripMarkup','summarizedField','summaryFilterItems','summaryForeignKey','summaryOperation','trackFeedHistory','trackHistory','trackTrending','type_x','unique','valueSet','visibleLines','writeRequiresMasterRead'};
    }

    public class LookupFilter {
        public Boolean active;
        public String booleanFilter;
        public String description;
        public String errorMessage;
        public MetadataServiceController.FilterItem[] filterItems;
        public String infoMessage;
        public Boolean isOptional;
        private String[] active_type_info = new String[]{'active',strSoapUrl,null,'1','1','false'};
        private String[] booleanFilter_type_info = new String[]{'booleanFilter',strSoapUrl,null,'0','1','false'};
        private String[] description_type_info = new String[]{'description',strSoapUrl,null,'0','1','false'};
        private String[] errorMessage_type_info = new String[]{'errorMessage',strSoapUrl,null,'0','1','false'};
        private String[] filterItems_type_info = new String[]{'filterItems',strSoapUrl,null,'0','-1','false'};
        private String[] infoMessage_type_info = new String[]{'infoMessage',strSoapUrl,null,'0','1','false'};
        private String[] isOptional_type_info = new String[]{'isOptional',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'active','booleanFilter','description','errorMessage','filterItems','infoMessage','isOptional'};
    }

    public class FilterItem {
        public String field;
        public String operation;
        public String value;
        public String valueField;
        private String[] field_type_info = new String[]{'field',strSoapUrl,null,'1','1','false'};
        private String[] operation_type_info = new String[]{'operation',strSoapUrl,null,'1','1','false'};
        private String[] value_type_info = new String[]{'value',strSoapUrl,null,'0','1','false'};
        private String[] valueField_type_info = new String[]{'valueField',strSoapUrl,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'field','operation','value','valueField'};
    }

    public class ValueSet {
        public String controllingField;
        public Boolean restricted;
        public MetadataServiceController.ValueSetValuesDefinition valueSetDefinition;
        public String valueSetName;
        public MetadataServiceController.ValueSettings[] valueSettings;
        private String[] controllingField_type_info = new String[]{'controllingField',strSoapUrl,null,'0','1','false'};
        private String[] restricted_type_info = new String[]{'restricted',strSoapUrl,null,'0','1','false'};
        private String[] valueSetDefinition_type_info = new String[]{'valueSetDefinition',strSoapUrl,null,'0','1','false'};
        private String[] valueSetName_type_info = new String[]{'valueSetName',strSoapUrl,null,'0','1','false'};
        private String[] valueSettings_type_info = new String[]{'valueSettings',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'controllingField','restricted','valueSetDefinition','valueSetName','valueSettings'};
    }

    public class ValueSettings {
        public String[] controllingFieldValue;
        public String valueName;
        private String[] controllingFieldValue_type_info = new String[]{'controllingFieldValue',strSoapUrl,null,'0','-1','false'};
        private String[] valueName_type_info = new String[]{'valueName',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'controllingFieldValue','valueName'};
    }

    public class ValueSetValuesDefinition {
        public Boolean sorted;
        public MetadataServiceController.CustomValue[] value;
        private String[] sorted_type_info = new String[]{'sorted',strSoapUrl,null,'1','1','false'};
        private String[] value_type_info = new String[]{'value',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'sorted','value'};
    }

    public virtual class CustomValue extends Metadata {
        public String color;
        public Boolean default_x;
        public String description;
        public Boolean isActive;
        public String label;
    }

    public class CustomLabel extends Metadata {
        public String type = 'CustomLabel';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',strSoapUrl,null,'0','1','false'};
        public String categories;
        public String language;
        public Boolean protected_x;
        public String shortDescription;
        public String value;
        private String[] categories_type_info = new String[]{'categories',strSoapUrl,null,'0','1','false'};
        private String[] language_type_info = new String[]{'language',strSoapUrl,null,'1','1','false'};
        private String[] protected_x_type_info = new String[]{'protected',strSoapUrl,null,'1','1','false'};
        private String[] shortDescription_type_info = new String[]{'shortDescription',strSoapUrl,null,'1','1','false'};
        private String[] value_type_info = new String[]{'value',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'categories','language','protected_x','shortDescription','value'};
    }

    public class readTranslationsResponse_element implements IReadResponseElement {
        public MetadataServiceController.ReadTranslationsResult result;
        public IReadResult getResult() { return result; }
        private String[] result_type_info = new String[]{'result',strSoapUrl,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    public class ReadTranslationsResult implements IReadResult {
        public MetadataServiceController.Translations[] records;
        public MetadataServiceController.Metadata[] getRecords() { return records; }
        private String[] records_type_info = new String[]{'records',strSoapUrl,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{strSoapUrl,'true','false'};
        private String[] field_order_type_info = new String[]{'records'};
    }
}