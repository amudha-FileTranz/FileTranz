/*
 * Purpose : To handle the results of label creation.
 * Author  : Giri 
 */
public with sharing class HandleResultsController {
	/**
	 * This method is used to handle the result of field creation through metaApi.
	 * @param saveResult from LanguageConfigurationsController class
	 * @return String - error message.
	 */
	public static String handleSaveResults(MetadataServiceController.SaveResult saveResult) {
		String strMessage = '';
		if (saveResult == null || saveResult.success) {
			System.debug('Save Result is null or success is true');
			strMessage = Label.Success;
		}
		if (saveResult.errors != null) {
			System.debug('Errors found in Save Result');
			List<String> messages = new List<String>();
			messages.add((saveResult.errors.size() == 1 ? 'Error ' : 'Errors ') + 'occured processing component ' + saveResult.fullName + '.');
			for (MetadataServiceController.Error error : saveResult.errors) {
				messages.add(error.message + ' (' +	error.statusCode + ').' + (error.fields != null && error.fields.size() > 0 ? ' Fields ' + String.join(error.fields, ',') + '.' : ''));
			}
			strMessage = String.valueOf(saveResult.errors);
		}
		return strMessage;
	}
}