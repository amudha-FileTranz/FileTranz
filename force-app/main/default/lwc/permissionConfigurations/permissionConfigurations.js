/*
 *
 * Purpose : Screen for admins to set up access to filetranz components..
 * Author  : Giri
 *
 */

import deleteConfigurations from "@salesforce/apex/PermissionConfigurationsController.deleteConfigurations";
import getPermissionConfigurations from "@salesforce/apex/PermissionConfigurationsController.getPermissionConfigurations";
import getPermissionSets from "@salesforce/apex/PermissionConfigurationsController.getPermissionSets";
import savePermissions from "@salesforce/apex/PermissionConfigurationsController.savePermissions";
import updateConfiguration from "@salesforce/apex/PermissionConfigurationsController.updateConfiguration";
import logError from "@salesforce/apex/ErrorLogger.logError";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {LightningElement,track} from "lwc";
//Importing Custom Labels
import ACTION from "@salesforce/label/c.ACTION";
import Add_Permission from "@salesforce/label/c.Add_Permission";
import Are_you_sure_you_want_to_delete_it from "@salesforce/label/c.Are_you_sure_you_want_to_delete_it";
import Back_To_Home from "@salesforce/label/c.Back_To_Home";
import Cancel from "@salesforce/label/c.Cancel";
import Confirm_Delete from "@salesforce/label/c.Confirm_Delete";
import Delete from "@salesforce/label/c.Delete";
import Download from "@salesforce/label/c.Download";
import EDIT from "@salesforce/label/c.EDIT";
import Error from "@salesforce/label/c.Error";
import Error_Message_Something_went from "@salesforce/label/c.Error_Message_Something_went";
import File_Access from "@salesforce/label/c.File_Access";
import No from "@salesforce/label/c.No";
import Org_wide_help_text from "@salesforce/label/c.Org_wide_help_text";
import File_Access_Help_Text from "@salesforce/label/c.File_Access_Help_Text";
import PREVIEW from "@salesforce/label/c.PREVIEW";
import Permission_Configuration from "@salesforce/label/c.Permission_Configuration";
import Permission_Set_Name from "@salesforce/label/c.Permission_Set";
import Profile_User_Configuration from "@salesforce/label/c.Profile_User_Configuration";
import Profile_User_Configuration_help_text from "@salesforce/label/c.Profile_User_Configuration_help_text";
import Save from "@salesforce/label/c.Save";
import Success from "@salesforce/label/c.Success";
import Success_message from "@salesforce/label/c.Success_message";
import UPLOAD from "@salesforce/label/c.UPLOAD";
import VIEW from "@salesforce/label/c.VIEW";
import Yes from "@salesforce/label/c.Yes";
import No_permission_configuration_found from "@salesforce/label/c.No_permission_configuration_found";
import Success_message_for_Update_the_Configuration from "@salesforce/label/c.Success_message_for_Update_the_Configuration";
import successfully_message_for_Permissions_assigned from "@salesforce/label/c.successfully_message_for_Permissions_assigned";
import filetranzcustomstyle from "@salesforce/resourceUrl/filetranzcustomstyle";
import {loadStyle} from "lightning/platformResourceLoader";



//const DELAY = 300;

export default class PermissionConfigurations extends LightningElement {
    // Create Permission Variables
    @track bolView = false;
    @track bolUpload = false;
    @track bolDownload = false;
    @track bolPreview = false;
    @track bolEdit = false;
    @track bolDelete = false;
    @track bolShowPill = false;
    @track bolHideConfigTable = false;
    @track arrPSoptions = [];
    @track arrPermissionSetsdata;
    @track arrSelectedPermissionSets = [];

    // Retrieve Permissions variable
    @track arrPermissionConfigurations = [];
    mapPermissionConfigsToUpdate = new Map();
    strSearchTerm = "";
    // Delete Permissions variable
    bolConfirmDelete = false;
    bolShowMassDelete = false;
    arrConfigurationDeleteIds = [];
    bolSelectAll = false;
    bolSave = false;

    // Spinner
    bolSpinner = false;

    bolShowPermissionForm = false;

    //Custom Labels
    CUSTOM_LABELS = {
        ACTION,
        Are_you_sure_you_want_to_delete_it,
        Add_Permission,
        Back_To_Home,
        Save,
        Cancel,
        Confirm_Delete,
        EDIT,
        Delete,
        PREVIEW,
        Permission_Set_Name,
        Permission_Configuration,
        VIEW,
        UPLOAD,
        Download,
        File_Access,
        Yes,
        No,
        Profile_User_Configuration,
        Org_wide_help_text,
        Profile_User_Configuration_help_text,
        Error,
        Error_Message_Something_went,
        Success,
        Success_message,
        File_Access_Help_Text,
        No_permission_configuration_found
    };

    get bolDisableSave() {
        return this.arrSelectedPermissionSets.length == 0 || (!this.bolView && !this.bolUpload);
    }


    connectedCallback() {
        this.getPermissionSetOptions();
        this.getPermissionConfigurations();
        loadStyle(this, filetranzcustomstyle);
    }

    renderedCallback() {
        window.scrollTo(0, 0);
    }

    // To retrieve permission sets which are not configured yet.
    getPermissionSetOptions() {
        this.bolSpinner = true;
        getPermissionSets().then((result) => {
            this.arrPermissionSetsdata = result;
            this.assignPSValues();
            this.bolSpinner = false;
        });
    }

    // To assign permission set picklist values.
    assignPSValues() {
        if (this.arrPermissionSetsdata) {
            if (this.arrPermissionSetsdata.length == 0) {
                return;
            }
            let arrOptions = [];
            let arrSelectedIds = [];
            for (let m = 0; m < this.arrSelectedPermissionSets.length; m++) {
                arrSelectedIds.push(this.arrSelectedPermissionSets[m].name);
            }
            for (let l = 0; l < this.arrPermissionSetsdata.length; l++) {
                if (!arrSelectedIds.includes(this.arrPermissionSetsdata[l].Id)) {
                    arrOptions.push({
                        value: this.arrPermissionSetsdata[l].Label,
                        key: this.arrPermissionSetsdata[l].Id
                    });
                }
            }
            this.arrPSoptions = arrOptions;
            this.arrPSoptions.sort((a, b) => (a.value > b.value ? 1 : b.value > a.value ? -1 : 0));
        }
    }

    // To retrieve configured records.
    getPermissionConfigurations() {
        this.bolSpinner = true;
        this.arrPermissionConfigurations = [];
        getPermissionConfigurations()
            .then((result) => {
                if (result) {
                    this.bolHideConfigTable = false;
                    result.forEach((record) => {
                        this.arrPermissionConfigurations.push(record);
                    });
                }
                if (result.length == 0) {
                    this.bolHideConfigTable = true;
                }
                this.bolSpinner = false;
                this.bolSave = false;
            })
            .catch((error) => {
                this.bolHideConfigTable = true;
                this.objLogErrorWrapper = {};
                this.objLogErrorWrapper.relatedTo = "PermissionConfigurationsController.getPermissionConfigurations";
                this.objLogErrorWrapper.summary = "";
                this.objLogErrorWrapper.message = error;
                this.objLogErrorWrapper.batchJobId = "";
                this.objLogErrorWrapper.recordIds = this.recordId;
                this.objLogErrorWrapper.statusCode = "";
                logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
                this.showNotification(Error, Error_Message_Something_went, "Error");
                this.bolSpinner = false;
            });
    }

    // Create permissions logics.
    savePermissions() {
        this.bolSpinner = true;
        let arrPSids = [];
        for (let i = 0; i < this.arrSelectedPermissionSets.length; i++) {
            arrPSids.push(this.arrSelectedPermissionSets[i].name);
        }
        let strAccess =
            (this.bolUpload ? "Upload; " : "") +
            (this.bolView ? "View; " : "") +
            (this.bolDownload ? "Download; " : "") +
            (this.bolEdit ? "Edit; " : "") +
            (this.bolDelete ? "Delete; " : "") +
            (this.bolPreview ? "Preview; " : "");

        savePermissions({
                lstPSids: arrPSids,
                strAccess: strAccess.slice(0, -2)
            })
            .then((result) => {
                if (result) {
                    this.bolView = false;
                    this.bolUpload = false;
                    this.bolDownload = false;
                    this.bolPreview = false;
                    this.bolEdit = false;
                    this.bolDelete = false;
                    this.bolShowPill = false;
                    this.showNotification(Success, successfully_message_for_Permissions_assigned, "success");
                    this.getPermissionSetOptions();
                    this.getPermissionConfigurations();
                    this.hidePermissionDropdown();
                    this.bolShowPermissionForm = false;
                    this.arrSelectedPermissionSets = [];
                } else {
                    this.showNotification(Error, Error_Message_Something_went, "error");
                }
                this.bolSpinner = false;
            })
            .catch((error) => {
                this.showNotification("Error", error, "error");
                this.bolSpinner = false;
            });
    }

    // To handle dependent access update
    handleAccessChange(event) {
        this.bolSpinner = true;
        let strInput = event.currentTarget.dataset.name;
        var isChecked = event.target.checked;
        event.target.checked = !isChecked;
        switch (strInput) {
            case "view":
                this.bolView = event.target.checked;
                if (!this.bolView) {
                    this.bolDownload = false;
                    this.bolPreview = false;
                    this.bolEdit = false;
                    this.bolDelete = false;
                }
                break;
            case "upload":
                this.bolUpload = event.target.checked;
                break;
            case "download":
                this.bolDownload = event.target.checked;
                this.bolView = this.bolDownload ? true : this.bolView;
                break;
            case "preview":
                this.bolPreview = event.target.checked;
                this.bolView = this.bolPreview ? true : this.bolView;
                break;
            case "edit":
                this.bolEdit = event.target.checked;
                this.bolView = this.bolEdit ? true : this.bolView;
                break;
            case "delete":
                this.bolDelete = event.target.checked;
                this.bolView = this.bolDelete ? true : this.bolView;
                break;
            default:
        }
        this.bolSpinner = false;
    }

    // Data table inline edit logics.
    handleEdit(event) {
        let strConfigId = event.currentTarget.dataset.id;
        for (let i = 0; i < this.arrPermissionConfigurations.length; i++) {
            if (this.arrPermissionConfigurations[i].idConfiguration === strConfigId) {
                this.arrPermissionConfigurations[i].bolEditable = false;
                break;
            }
        }
    }

    // Handle permission change logics
    handlePermissionChange(event) {
        this.bolSave = true;
        let strConfigId = event.currentTarget.dataset.id;
        let strType = event.currentTarget.dataset.name;
        for (let i = 0; i < this.arrPermissionConfigurations.length; i++) {
            if (this.arrPermissionConfigurations[i].idConfiguration === strConfigId) {
                switch (strType) {
                    case "view":
                        this.arrPermissionConfigurations[i].bolView = event.target.checked;
                        if (!this.arrPermissionConfigurations[i].bolView) {
                            this.arrPermissionConfigurations[i].bolDownload = false;
                            this.arrPermissionConfigurations[i].bolPreview = false;
                            this.arrPermissionConfigurations[i].bolEdit = false;
                            this.arrPermissionConfigurations[i].bolDelete = false;
                        }
                        break;
                    case "upload":
                        this.arrPermissionConfigurations[i].bolUpload = event.target.checked;
                        break;
                    case "download":
                        this.arrPermissionConfigurations[i].bolDownload = event.target.checked;
                        this.arrPermissionConfigurations[i].bolView = this.arrPermissionConfigurations[i].bolDownload ? true : this.arrPermissionConfigurations[i].bolView;
                        break;
                    case "preview":
                        this.arrPermissionConfigurations[i].bolPreview = event.target.checked;
                        this.arrPermissionConfigurations[i].bolView = this.arrPermissionConfigurations[i].bolPreview ? true : this.arrPermissionConfigurations[i].bolView;
                        break;
                    case "edit":
                        this.arrPermissionConfigurations[i].bolEdit = event.target.checked;
                        this.arrPermissionConfigurations[i].bolView = this.arrPermissionConfigurations[i].bolEdit ? true : this.arrPermissionConfigurations[i].bolView;
                        break;
                    case "delete":
                        this.arrPermissionConfigurations[i].bolDelete = event.target.checked;
                        this.arrPermissionConfigurations[i].bolView = this.arrPermissionConfigurations[i].bolDelete ? true : this.arrPermissionConfigurations[i].bolView;
                        break;
                    default:
                }
                this.mapPermissionConfigsToUpdate.set(this.arrPermissionConfigurations[i].idConfiguration, this.arrPermissionConfigurations[i]);
                break;
            }
        }
        let arrtrElements = this.template.querySelectorAll("tr[data-id]");
        arrtrElements.forEach((tr) => {
            if (tr.dataset.id == strConfigId) {
                tr.style.backgroundColor = "#E9ECF5";
                tr.style.borderTop = "2px solid white";
                tr.style.borderBottom = "2px solid white";
            }
        });
    }

    // To handle update existing configuration record.
    handlePermissionUpdate() {
        let arrConfigurationsToUpdate = Array.from(this.mapPermissionConfigsToUpdate.values());
        this.bolSpinner = true;
        updateConfiguration({
                lstConfigurationWrappers: arrConfigurationsToUpdate
            })
            .then((result) => {
                if (result) {
                    this.getPermissionConfigurations();
                    this.showNotification(Success, Success_message_for_Update_the_Configuration, "Success");
                }
                this.bolSpinner = false;
            })
            .catch((error) => {
                this.objLogErrorWrapper = {};
                this.objLogErrorWrapper.relatedTo = "PermissionConfigurationsController.updateConfiguration";
                this.objLogErrorWrapper.summary = "";
                this.objLogErrorWrapper.message = error;
                this.objLogErrorWrapper.batchJobId = "";
                this.objLogErrorWrapper.recordIds = this.recordId;
                this.objLogErrorWrapper.statusCode = "";
                logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
                this.showNotification(Error, Error_Message_Something_went, "Error");
                this.bolSpinner = false;
            });
    }

    handleCancel() {
        this.mapPermissionConfigsToUpdate.clear();
        this.getPermissionConfigurations();
    }


    handleSearch(event) {
        event.stopPropagation();
        if (event.currentTarget.dataset.id === "searchBox") {
            this.template.querySelector(".industry_list").classList.remove("slds-hide");
            this.template.querySelector(".slds-dropdown-trigger").classList.add("slds-is-open");
        } else {
            this.strSearchTerm = "";
            this.assignPSValues();
            this.template.querySelector(".industry_list").classList.add("slds-hide");
            this.template.querySelector(".slds-dropdown-trigger").classList.remove("slds-is-open");
        }
    }

    handleSelect(event) {
        this.arrSelectedPermissionSets.push({
            label: event.currentTarget.dataset.name,
            name: event.currentTarget.dataset.id
        });
        this.strSearchTerm = "";
        this.assignPSValues();
        this.template.querySelector(".industry_list").classList.add("slds-hide");
        this.template.querySelector(".slds-dropdown").classList.add("slds-hide");
        this.bolShowPill = true;
    }

    handleMultiSelect(event) {
        if (event.target.checked) {
            for (let i = 0; i < this.arrPermissionConfigurations.length; i++) {
                this.arrPermissionConfigurations[i].bolSelect = event.target.checked;
                this.arrConfigurationDeleteIds.push(this.arrPermissionConfigurations[i].idConfiguration);
            }
            this.bolShowMassDelete = true;
        } else {
            this.arrPermissionConfigurations.forEach((element) => {
                element.bolSelect = false;
            });
            this.arrConfigurationDeleteIds = [];
            this.bolShowMassDelete = false;
            this.bolSelectAll = event.target.checked;
        }
    }

    handleConfirmDelete(event) {
        this.bolConfirmDelete = true;
        if (event.currentTarget.dataset.name != "massdelete") {
            this.arrConfigurationDeleteIds = [];
            this.arrConfigurationDeleteIds.push(event.currentTarget.dataset.id);
        }
    }

    handleSelection(event) {
        let strRecordId = event.currentTarget.dataset.id;
        let bolAction = event.target.checked;
        if (bolAction) {
            this.arrConfigurationDeleteIds.push(strRecordId);
        } else {
            for (let i = 0; i < this.arrConfigurationDeleteIds.length; i++) {
                if (this.arrConfigurationDeleteIds[i] === strRecordId) {
                    this.arrConfigurationDeleteIds.splice(i, 1);
                    break;
                }
            }
        }
        this.bolShowMassDelete = this.arrConfigurationDeleteIds.length > 0 ? true : false;
    }

    handleDelete() {
        this.bolSpinner = true;
        this.bolConfirmDelete = false;
        deleteConfigurations({
                lstConfigurationIds: this.arrConfigurationDeleteIds
            })
            .then((result) => {
                if (result) {
                    this.getPermissionConfigurations();
                    this.showNotification(Success, Success_message, "Success");
                    this.arrConfigurationDeleteIds = [];
                }
                this.bolSelectAll = false;
                this.bolSpinner = false;
                this.bolShowMassDelete = false;
            })
            .catch((error) => {
                this.objLogErrorWrapper = {};
                this.objLogErrorWrapper.relatedTo = "PermissionConfigurationsController.deleteConfigurations";
                this.objLogErrorWrapper.summary = "";
                this.objLogErrorWrapper.message = error;
                this.objLogErrorWrapper.batchJobId = "";
                this.objLogErrorWrapper.recordIds = this.recordId;
                this.objLogErrorWrapper.statusCode = "";
                logError({ strLogErrorWrapper : JSON.stringify(this.objLogErrorWrapper) });
                this.showNotification(Error, Error_Message_Something_went, "Error");
                this.bolSpinner = false;
            });
    }

    hideModalBox() {
        this.bolConfirmDelete = false;
    }

    handleSelectedPermissionRemove(event) {
        const intIndex = event.detail.index;
        this.arrPSoptions.push({
            value: this.arrSelectedPermissionSets[intIndex].label,
            key: this.arrSelectedPermissionSets[intIndex].name
        });
        this.arrPSoptions.sort((a, b) => {
            const c = a.value.toUpperCase();
            const d = b.value.toUpperCase();
            if (c < d) {
                return -1;
            }
            if (c > d) {
                return 1;
            }
            return 0;
        });
        this.arrSelectedPermissionSets.splice(intIndex, 1);
    }

    hidePermissionDropdown() {
        this.template.querySelector(".industry_list").classList.add("slds-hide");
        this.template.querySelector(".slds-dropdown").classList.add("slds-hide");
        this.assignPSValues();
    }

    handlePSValues(event) {
        this.strSearchTerm = event.target.value;
        let arrTempPSoptions = [];
        if (this.strSearchTerm != undefined && this.strSearchTerm != "") {
            for (let i = 0; i < this.arrPermissionSetsdata.length; i++) {
                let strName = this.arrPermissionSetsdata[i].Label.toLowerCase();
                if (strName.includes(this.strSearchTerm.toLowerCase())) {
                    arrTempPSoptions.push({
                        value: this.arrPermissionSetsdata[i].Label,
                        key: this.arrPermissionSetsdata[i].Id
                    });
                }
            }
            this.arrPSoptions = arrTempPSoptions;
            this.arrPSoptions.sort((a, b) => (a.value > b.value ? 1 : b.value > a.value ? -1 : 0));
        } else {
            this.assignPSValues();
        }
    }

    handleSwitchScreen() {
        this.bolShowPermissionForm = !this.bolShowPermissionForm;
        this.bolView = false;
        this.bolUpload = false;
        this.bolDownload = false;
        this.bolPreview = false;
        this.bolEdit = false;
        this.bolDelete = false;
        this.bolShowPill = false;
        this.arrSelectedPermissionSets = [];
    }

    // Common method for toast.
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}