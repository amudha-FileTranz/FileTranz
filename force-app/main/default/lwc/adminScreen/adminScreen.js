/*
 * Purpose : Parent screen of configuration settings.
 * Author  : Giri
 */
import { LightningElement } from 'lwc';
// Importing Custom Labels
import LANGUAGE_SETUP from "@salesforce/label/c.LANGUAGE_SETUP";
import Manage_Jobs from "@salesforce/label/c.Manage_Jobs";
import ORG_WIDE from "@salesforce/label/c.ORG_WIDE";
import Permissions from "@salesforce/label/c.Permissions";
import STORAGE from "@salesforce/label/c.STORAGE";

export default class AdminScreen extends LightningElement {
    renderedCallback() {/*fixing even height of admin body content section*/
        const height = window.innerHeight|| document.documentElement.clientHeight|| 
        document.body.clientHeight;
        let divheight = this.template.querySelector('[data-id="bodycontainer"]');
        // divheight.style.height = (height - 0) + "px";            
    }
    bolAdminConfig = true;
    bolConfig = false;
    bolProfileConfig = false;
    bolLanguageSetup = false;
    bolScheduleConfig = false;
    CUSTOM_LABELS = {
        STORAGE,
        ORG_WIDE,
        LANGUAGE_SETUP,
        Manage_Jobs,
        Permissions
    };

    get strStorageConfigClass() {
        return this.bolAdminConfig === true ? 'vnav active tooltip' : 'vnav tooltip';
    }

    get strOrgConfigClass() {
        return this.bolConfig === true ? 'vnav active tooltip' : 'vnav tooltip';
    }

    get strProfileConfigClass() {
        return this.bolProfileConfig === true ? 'vnav active tooltip' : 'vnav tooltip';
    }

    get strJobConfigClass() {
        console.log('this.bolScheduleConfig', this.bolScheduleConfig);
        return this.bolScheduleConfig === true ? 'vnav active tooltip' : 'vnav tooltip';
    }

    get strLangConfigClass() {
        return this.bolLanguageSetup === true ? 'vnav active tooltip' : 'vnav tooltip';
    }

    // Manage Menu selections
    setMenuSelected(event) {
        switch (event.currentTarget.dataset.id) {
            case "storageconfig":
                this.bolAdminConfig = true;
                this.bolConfig = false;
                this.bolProfileConfig = false;
                this.bolLanguageSetup = false;
                this.bolScheduleConfig = false;
                break;
            case "orgconfig":
                this.bolConfig = true;
                this.bolAdminConfig = false;
                this.bolProfileConfig = false;
                this.bolLanguageSetup = false;
                this.bolScheduleConfig = false;
                break;
            case "profileconfig":
                this.bolProfileConfig = true;
                this.bolConfig = false;
                this.bolAdminConfig = false;
                this.bolLanguageSetup = false;
                this.bolScheduleConfig = false;
                break;
            case "languageconfig":
                this.bolLanguageSetup = true;
                this.bolProfileConfig = false;
                this.bolConfig = false;
                this.bolAdminConfig = false;
                this.bolScheduleConfig = false;
                break;
            case "scheduleapexconfig":
                this.bolScheduleConfig = true;
                this.bolLanguageSetup = false;
                this.bolProfileConfig = false;
                this.bolConfig = false;
                this.bolAdminConfig = false;
                break;
            default:
        }
    }

}