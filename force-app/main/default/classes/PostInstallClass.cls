/*
 * Purpose : To execute the post installation/upgrade scripts
 * Author  : Anandh
 */
Public with sharing class PostInstallClass implements InstallHandler {
    Public void onInstall(InstallContext context) {
        try {
            // For installation activities
            if(context.previousVersion() == null) {
                seedDefaultConfigurations();
            }
        } catch (Exception exp) {
            // An uncaught exception here would fail the entire package install/upgrade for the
            // subscriber, so every failure is logged and swallowed instead of propagated.
            ErrorLogger.logException('PostInstallClass.onInstall', exp);
        }
    }

    private void seedDefaultConfigurations() {
        List<Configuration__c> lstConfigurations = new List<Configuration__c>();
            Configuration__c objConfig1 = new Configuration__c();
            objConfig1.Configuration_Name__c = 'Batch_job_Names';
            objConfig1.Long_Value__c = 'MigrateAttachmentsBatch; MigrateFilesBatch; EmptyRecycleBinBatch; LogActivityExportBatch; MigrateCDLFilesBatch; MigrateFileVersionsBatch; DeleteContentDocumentsBatch; DeleteExternalFilesBatch;';
            objConfig1.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig1);
            
            Configuration__c objConfig2 = new Configuration__c();
            objConfig2.Configuration_Name__c = 'Log_Activity';
            objConfig2.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig2);
            
            Configuration__c objConfig3 = new Configuration__c();
            objConfig3.Configuration_Name__c = 'Recycle_Bin';
            objConfig3.Long_Value__c = 'false';
            objConfig3.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig3);
            
            Configuration__c objConfig4 = new Configuration__c();
            objConfig4.Configuration_Name__c = 'Language';
            objConfig4.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig4);
            
            Configuration__c objConfig5 = new Configuration__c();
            objConfig5.Configuration_Name__c = 'Restrict_File_Types';
            objConfig5.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig5);
            
            Configuration__c objConfig6 = new Configuration__c();
            objConfig6.Configuration_Name__c = 'File_Limit';
            objConfig6.Long_Value__c = '15';
            objConfig6.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig6);
            
            Configuration__c objConfig7 = new Configuration__c();
            objConfig7.Configuration_Name__c = 'Log_Activity_Emails';
            objConfig7.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig7);
            
            Configuration__c objConfig8 = new Configuration__c();
            objConfig8.Configuration_Name__c = 'Clear_Recycle_Bin_In';
            objConfig8.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig8);
            
            Configuration__c objConfig9 = new Configuration__c();
            objConfig9.Configuration_Name__c = 'File_Privileges';
            objConfig9.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig9);
            
            Configuration__c objConfig10 = new Configuration__c();
            objConfig10.Configuration_Name__c = 'Upload_Size_Limit';
            objConfig10.Long_Value__c = '1024';
            objConfig10.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig10);
            
            Configuration__c objConfig11 = new Configuration__c();
            objConfig11.Configuration_Name__c = 'File_Types';
            objConfig11.Long_Value__c = '.bmp; .csv; .css; .doc; .docx; .dot; .gif; .gpg; .htm; .html; .ics; .jpeg; .jpg; .js; .mdb; .mov; .mp3; .mp4; .mpeg; .mpg; .ogg; .pdf; .png; .pps; .ppsx; .ppt; .pptx; .rtf; .sxc; .sxi; .swf; .tif; .tiff; .txt; .vdi; .vsd; .wav; .xls; .xlsx; .xml; .xsl; .xslt; .zip';
            objConfig11.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig11);
            
            Configuration__c objConfig12 = new Configuration__c();
            objConfig12.Configuration_Name__c = 'Preview_Formats';
            objConfig12.Long_Value__c = '.bmp; .cls; .css; .gif; .htm; .html; .jpeg; .jpg; .js; .mp3; .ogg; .pdf; .png; .txt; .xml; .xsl; .xslt; .webm; .webp; .m4a; .mp4';
            objConfig12.Configuration_Type__c = 'File Configuration';
            lstConfigurations.add(objConfig12);
            
            Configuration__c objConfig13 = new Configuration__c();
            objConfig13.Configuration_Name__c = 'OWD';
            objConfig13.Configuration_Type__c = 'Permission Configuration';
            lstConfigurations.add(objConfig13);

            // Idempotency guard: an uninstall/reinstall cycle (or a partially-completed prior
            // install) resets previousVersion() to null and re-enters this method, so only
            // insert the default rows that don't already exist rather than duplicating them.
            Set<String> setExistingNames = new Set<String>();
            for (Configuration__c objExisting : [SELECT Configuration_Name__c FROM Configuration__c WHERE Configuration_Name__c != null WITH USER_MODE]) {
                setExistingNames.add(objExisting.Configuration_Name__c);
            }
            List<Configuration__c> lstConfigurationsToInsert = new List<Configuration__c>();
            for (Configuration__c objConfig : lstConfigurations) {
                if (!setExistingNames.contains(objConfig.Configuration_Name__c)) {
                    lstConfigurationsToInsert.add(objConfig);
                }
            }

            if(Schema.SObjectType.Configuration__c.isCreateable() && Schema.SObjectType.Configuration__c.fields.Configuration_Name__c.isCreateable()
                && Schema.SObjectType.Configuration__c.fields.Configuration_Type__c.isCreateable()
                && Schema.SObjectType.Configuration__c.fields.Long_Value__c.isCreateable() && !lstConfigurationsToInsert.isEmpty()){

                SObjectAccessDecision objAccessDecision = Security.stripInaccessible(AccessType.CREATABLE, lstConfigurationsToInsert);
                List<Configuration__c> lstConfigurationsCreatable = (List<Configuration__c>)objAccessDecision.getRecords();

                if (!lstConfigurationsCreatable.isEmpty()) {
                    insert as User lstConfigurationsCreatable;
                }
            }
    }
}