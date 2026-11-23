/*
 * Purpose : To enable/disable multi language translations.
 * Author  : Giri
 */

import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, track } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
// Importing Apex Methods
import logError from "@salesforce/apex/ErrorLogger.logError";
import createTranslation from "@salesforce/apex/LanguageConfigurationsController.createTranslation";
import getTranslation from "@salesforce/apex/LanguageConfigurationsController.getTranslation";
import getAvailableLanguages from "@salesforce/apex/LanguageConfigurationsController.getAvailableLanguages";
import afterInstallUpdateMdt from "@salesforce/apex/LanguageConfigurationsController.afterInstallUpdateMdt";

// Importing Custom labels
import All_available_languages_are_Installed from "@salesforce/label/c.All_available_languages_are_Installed";
import All_languages_updated_successfully from "@salesforce/label/c.All_languages_updated_successfully";
import Available_Languages from "@salesforce/label/c.Available_Languages";
import Error from "@salesforce/label/c.Error";
import INSTALL_ALL from "@salesforce/label/c.INSTALL_ALL";
import Install_Language from "@salesforce/label/c.Install_Language";
import Install_all_languages_in_a_single_click from "@salesforce/label/c.Install_all_languages_in_a_single_click";
import Installed_Languages from "@salesforce/label/c.Installed_Languages";
import Language_setup_help_text from "@salesforce/label/c.Language_setup_help_text";
import Language_updated_successfully from "@salesforce/label/c.Language_updated_successfully";
import Other_Supported_Languages from "@salesforce/label/c.Other_Supported_Languages";
import Success from "@salesforce/label/c.Success";
import This_Language_is_not_enabled_in_your_Org from "@salesforce/label/c.This_Language_is_not_enabled_in_your_Org";
import Loading from "@salesforce/label/c.Loading";
import Something_went_wrong from "@salesforce/label/c.Something_went_wrong";
import filetranzcustomstyle from "@salesforce/resourceUrl/filetranzcustomstyle";

// Importing Static Resources
import tt_img from "@salesforce/resourceUrl/tt_img";

export default class LanguageConfigurations extends LightningElement {
	@track arrInstalledLanguages = [];
	@track arrAvailableLanguages = [];
	@track arrOtherSupportedLanguages = [];
	strLanFolderUrl = tt_img + "/tt_img/lanFolder.svg";
	strChkIconUrl = tt_img + "/tt_img/awesome-check-circle.svg";
	strDownloadIconUrl = tt_img + "/tt_img/ionic-md-download.svg";
	bolInstallAll = false;
	strFinalResult = "";
	CUSTOM_LABELS = {
		Language_updated_successfully,
		All_languages_updated_successfully,
		All_available_languages_are_Installed,
		Install_Language,
		Other_Supported_Languages,
		Language_setup_help_text,
		Installed_Languages,
		Available_Languages,
		Install_all_languages_in_a_single_click,
		INSTALL_ALL,
		This_Language_is_not_enabled_in_your_Org,
		Success,
		Error,
		Loading,
        Something_went_wrong
	};

	connectedCallback() {
		this.getLanguages();
		loadStyle(this, filetranzcustomstyle);
		
	}

	renderedCallback() {
		window.scrollTo(0, 0);
	}
	
	// To query available languages
	getLanguages() {
		getAvailableLanguages()
			.then((result) => {			
				let intSno = 0;
				this.arrInstalledLanguages = [];
				this.arrAvailableLanguages = [];
				this.arrOtherSupportedLanguages = [];
				result.forEach((element) => {
					if (element.isInstalled) {
						this.arrInstalledLanguages.push(element);
					} else if (!element.isInstalled && element.isActive) {
						element.isLoading = false;
						element.isDisabled = false;
						element.intSno = intSno;
						this.arrAvailableLanguages.push(element);
						intSno++;
					} else if (!element.isActive) {
						this.arrOtherSupportedLanguages.push(element);						
					}
				});
				if (this.arrAvailableLanguages.length === 0) {
					this.arrAvailableLanguages = null;
					this.bolInstallAll = true;
				}
				if (this.arrOtherSupportedLanguages.length === 0) {
					this.arrOtherSupportedLanguages = null;
				}
			})
			.catch((error) => {
				this.objLogErrorWrapper = {};
				this.objLogErrorWrapper.relatedTo = "languageConfigurations LWC -getAvailableLanguages ";
				this.objLogErrorWrapper.summary = "";
				this.objLogErrorWrapper.message = error;
				this.objLogErrorWrapper.batchJobId = "";
				this.objLogErrorWrapper.recordIds = "";
				this.objLogErrorWrapper.statusCode = "";
				logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
			});
	}

	// To handle install languages logics
	async handleInstall(event) {
		this.strFinalResult = "";
		let index;
		try{
			let strLangCode = event.currentTarget.dataset.language;
			index = event.currentTarget.dataset.index;
			let strLanguageLabel = event.currentTarget.dataset.id;
			this.arrAvailableLanguages[index].isLoading = true;
			this.arrAvailableLanguages[index].isDisabled = true;
			await this.createTranslation(strLangCode);

			if (this.strFinalResult == "") {
				afterInstallUpdateMdt({
					strLanguage: strLangCode
				}).then((result) => {
					this.showNotification(
						Success,
						strLanguageLabel + " " + Language_updated_successfully,
						"success"
					);
				}).catch((error) => {
					if(index !== undefined && this.arrAvailableLanguages[index]){
						this.arrAvailableLanguages[index].isLoading = false;
					}
					this.objLogErrorWrapper = {};
                    this.objLogErrorWrapper.relatedTo = "languageConfigurations LWC - afterInstallUpdateMdt ";
                    this.objLogErrorWrapper.summary = "";
                    this.objLogErrorWrapper.message = error;
                    this.objLogErrorWrapper.batchJobId = "";
                    this.objLogErrorWrapper.recordIds = "";
                    this.objLogErrorWrapper.statusCode = "";
                    logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
				});
			} else {
				this.showNotification(Error, this.strFinalResult, "error");
			}
			// this.arrAvailableLanguages[index].isLoading = false;
			setTimeout(() => {
				this.getLanguages();
			}, 3000);
		}catch (error) {
  			this.arrAvailableLanguages[index].isLoading = false;
			  this.objLogErrorWrapper = {};
			  this.objLogErrorWrapper.relatedTo = "languageConfigurations LWC - handleInstall ";
			  this.objLogErrorWrapper.summary = "";
			  this.objLogErrorWrapper.message = error;
			  this.objLogErrorWrapper.batchJobId = "";
			  this.objLogErrorWrapper.recordIds = "";
			  this.objLogErrorWrapper.statusCode = "";
			  logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
		}
	}

	// To handle install all logics
	async handleInstallAll() {
		this.strFinalResult = "";
		try {
			this.arrAvailableLanguages.forEach((element) => {
				element.isLoading = true;
				element.isDisabled = true;
			});
			
			for(let i = 0; i < this.arrAvailableLanguages.length; i++) {
				let strLangCode = this.arrAvailableLanguages[i].strLanguageCode;
				await this.createTranslation(strLangCode);
			}	
			if (this.strFinalResult == "") {
				this.showNotification(
					Success,
					All_languages_updated_successfully,
					"success"
				);
			} else {
				this.showNotification(Error, this.strFinalResult, "error");
			}
			this.getLanguages();
		} catch (error) {
			this.arrAvailableLanguages.forEach((element) => {
				element.isLoading = false;
				element.isDisabled = false;
				this.objLogErrorWrapper = {};
				this.objLogErrorWrapper.relatedTo = "languageConfigurations LWC - handleInstallAll ";
				this.objLogErrorWrapper.summary = "";
				this.objLogErrorWrapper.message = error;
				this.objLogErrorWrapper.batchJobId = "";
				this.objLogErrorWrapper.recordIds = "";
				this.objLogErrorWrapper.statusCode = "";
				logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
			});
		}
	}

	async createTranslation(strLangCode) {
		let arrayTranslations = [];
		await getTranslation({
			strLanguage: strLangCode,
		}).then((result) => {
			arrayTranslations = [...result];

		}).catch((error) => {
			this.objLogErrorWrapper = {};
				this.objLogErrorWrapper.relatedTo = "languageConfigurations LWC -getTranslation ";
				this.objLogErrorWrapper.summary = "";
				this.objLogErrorWrapper.message = error;
				this.objLogErrorWrapper.batchJobId = "";
				this.objLogErrorWrapper.recordIds = "";
				this.objLogErrorWrapper.statusCode = "";
				logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
		});

		let bolFinal = false;
		if(arrayTranslations.length > 0){
			for (let i = 0; i < arrayTranslations.length; i = i + 100) {
				
				let lstTranslations = [...arrayTranslations.slice(i, i + 100)];
	
				await createTranslation({
					strLanguage: strLangCode,
					lstLabelTranslations: lstTranslations,
					bolFinal: bolFinal,
				}).then((result) => {
					if(this.strFinalResult != result){
						this.strFinalResult += result;	
					}
				}).catch((error) => {
					this.objLogErrorWrapper = {};
					this.objLogErrorWrapper.relatedTo = "languageConfigurations LWC -createTranslation";
					this.objLogErrorWrapper.summary = "";
					this.objLogErrorWrapper.message = error;
					this.objLogErrorWrapper.batchJobId = "";
					this.objLogErrorWrapper.recordIds = "";
					this.objLogErrorWrapper.statusCode = "";
					logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
				});
			}
		}else{
			this.strFinalResult = Something_went_wrong;
		}
	}	

	// Generic Toast method
	showNotification(strTitle, strMessage, strType) {
		const objToastEvent = new ShowToastEvent({
			title: strTitle,
			message: strMessage,
			variant: strType,
		});
		this.dispatchEvent(objToastEvent);
	}
}