/*
 * Purpose : To get session Id details
 * Author  : Giri
 */
public with sharing class SessionIdController {

   /**
    * Extracts the session Id rendered by the SessionId Visualforce page via $Api.Session_ID.
    * AppExchange Security Review note: this session Id is used only to authenticate a SOAP
    * callout back to this same org's own Metadata API (see MetadataServiceController.createService)
    * - it is never sent to an external host, logged, or exposed to the client. The only caller,
    * LanguageConfigurationsController.createTranslation, additionally requires the FileTranz_Admin
    * permission set (CommonUtilities.isFileTranzAdmin()).
    * @param visualforcePage from MetadataServiceController
    * @return String - SessionId from the VF page.
    */
    @SuppressWarnings('PMD.AvoidUnauthorizedGetSessionIdInApex')
    public static String getSessionIdFromVFPage(PageReference visualforcePage) {
        String strContent = '';
        if (!Test.isRunningTest()) {
            strContent = visualforcePage.getContent().toString();
        } else {
             strContent = 'Start_Of_Session_Id556557546645544End_Of_Session_Id';
            }
        Integer intStartIndex = strContent.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
        intEndIndex = strContent.indexOf('End_Of_Session_Id');
        return strContent.substring(intStartIndex, intEndIndex);
    }
        
}