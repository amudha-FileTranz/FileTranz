/*
 * Purpose : This class contains methods for sending emails of various configurations.
 * Author  : Giri
 */
public inherited sharing class EmailUtility {
    public String strSubject;
    public String strhtmlBody;
    private Id idTargetObjectId;
    public Set<Id> setTargetObjectIds;
    public Boolean bolSaveAsActivity = false;

    private static String escapeHtml(String input) {
        if (String.isBlank(input)) {
            return input;
        }

        return input
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
    }

    private static String prepareHtmlBody(String strInput) {
        if (String.isBlank(strInput)) {
            return strInput;
        }

        String strSanitized = escapeHtml(strInput);

        strSanitized = strSanitized
            .replace('&lt;br /&gt;', '<br />')
            .replace('&lt;br/&gt;', '<br/>')
            .replace('&lt;b&gt;', '<b>')
            .replace('&lt;/b&gt;', '</b>')
            .replace('&lt;p&gt;', '<p>')
            .replace('&lt;/p&gt;', '</p>');

        return strSanitized;
    }

    public void sendEmail() {
        List<Messaging.SingleEmailMessage> lstEmails =
            new List<Messaging.SingleEmailMessage>();

        if (setTargetObjectIds != null && !setTargetObjectIds.isEmpty()) {

            if (!Schema.SObjectType.User.isAccessible() || !Schema.SObjectType.User.fields.Email.isAccessible()) {
                throw new AuraHandledException(
                    'You do not have access to User Email field. Please contact your administrator.'
                );
            }

            for (Id idTargetId : setTargetObjectIds) {
                idTargetObjectId = idTargetId;

                Messaging.SingleEmailMessage objMail = prepareEmail();

                if (objMail != null) {
                    lstEmails.add(objMail);
                }
            }

            if (!lstEmails.isEmpty()) {
                Messaging.sendEmail(lstEmails);
            }
        }
    }

    @SuppressWarnings('PMD.ApexDangerousMethods')
    public Messaging.SingleEmailMessage prepareEmail() {

        Messaging.SingleEmailMessage objMail =
            new Messaging.SingleEmailMessage();

        if (!String.isBlank(strSubject)) {
            objMail.setSubject(escapeHtml(strSubject));
        }

        if (!String.isBlank(strhtmlBody)) {
            objMail.setHtmlBody(prepareHtmlBody(strhtmlBody));
        }

        if (idTargetObjectId != null
            && idTargetObjectId.getSObjectType() == User.SObjectType
            && Schema.SObjectType.User.isAccessible()) {

            objMail.setTargetObjectId(idTargetObjectId);
        }

        if (bolSaveAsActivity && Schema.SObjectType.Task.isCreateable()) {
            objMail.setSaveAsActivity(bolSaveAsActivity);
        }
        
        return objMail;
    }
}