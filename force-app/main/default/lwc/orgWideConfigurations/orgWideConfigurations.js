/*
 * Purpose : Screen for admins to set up the org wide configurations. 
 * Author  : Anandhakumar Thangasamy
 */
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, track, wire } from "lwc";
// Importing Apex Methods
import fetchAllObjectName from '@salesforce/apex/CommonUtilities.getAllObjectName';
import getConfigurations from "@salesforce/apex/OrgWideConfigurationsController.getConfigurations";
import updateConfigurations from "@salesforce/apex/OrgWideConfigurationsController.updateConfigurations";
import isRecycleBinAllowed from "@salesforce/apex/OrgWideConfigurationsController.isRecycleBinAllowed"; // New method for recycle bin feature
import setFileSizeLimits from "@salesforce/apex/OrgWideConfigurationsController.setFileSizeLimits"; // New method for file size limits
import setFileUploadLimits from "@salesforce/apex/OrgWideConfigurationsController.setFileUploadLimits"; // New method for file upload limits  
// Importing Custom Labels
import ACTIVE from "@salesforce/label/c.ACTIVE";
import A_maximum_of from "@salesforce/label/c.A_maximum_of";
import Available_Actions from "@salesforce/label/c.Available_Actions";
import Available_Types from "@salesforce/label/c.Available_Types";
import Cancel from "@salesforce/label/c.Cancel";
import Days_FileTranz from "@salesforce/label/c.Days_FileTranz";
import Delete from "@salesforce/label/c.Delete";
import Download from "@salesforce/label/c.Download";
import EDIT from "@salesforce/label/c.EDIT";
import Error from "@salesforce/label/c.Error";
import File_Limit from "@salesforce/label/c.File_Limit";
import File_Size_Limit_Help_text from "@salesforce/label/c.File_Size_Limit_Help_text";
import File_Specifications from "@salesforce/label/c.File_Specifications";
import Files_Uploaded from "@salesforce/label/c.Files_Uploaded";
import INACTIVE from "@salesforce/label/c.INACTIVE";
import Loading from "@salesforce/label/c.Loading";
import Log_Activity from "@salesforce/label/c.Log_Activity";
import Recycle_Bin from "@salesforce/label/c.Recycle_Bin";
import Maximum_File_Size from "@salesforce/label/c.Maximum_File_Size";
import Maximum_File_Size_Description from "@salesforce/label/c.Maximum_File_Size_Description";
import Max_File_Limit from "@salesforce/label/c.Max_File_Limit";
import Maximum_File_Limit_Description from "@salesforce/label/c.Maximum_File_Limit_Description";
import Maintain_Deleted_Files from "@salesforce/label/c.Maintain_Deleted_Files";
import Option_Enabled from "@salesforce/label/c.Option_Enabled";
import Org_Wide_Configuration from "@salesforce/label/c.Org_Wide_Configuration";
import Org_Wide_Configuration_help_text from "@salesforce/label/c.Org_Wide_Configuration_help_text";
import PREVIEW from "@salesforce/label/c.PREVIEW";
import Save from "@salesforce/label/c.Save";
import Select_Orgwide from "@salesforce/label/c.Select_Orgwide";
import Select_Specification from "@salesforce/label/c.Select_Specification";
import Selected_Actions from "@salesforce/label/c.Selected_Actions";
import Selected_Types from "@salesforce/label/c.Selected_Types";
import Something_went_wrong from "@salesforce/label/c.Something_went_wrong";
import Success from "@salesforce/label/c.Success";
import The_settings_are_updated_sucessfully from "@salesforce/label/c.The_settings_are_updated_sucessfully";
import UPLOAD from "@salesforce/label/c.UPLOAD";
import VIEW from "@salesforce/label/c.VIEW";
import X10 from "@salesforce/label/c.X10";
import X100 from "@salesforce/label/c.X100";
import X12 from "@salesforce/label/c.X12";
import X15 from "@salesforce/label/c.X15";
import X150 from "@salesforce/label/c.X150";
import X200 from "@salesforce/label/c.X200";
import X25 from "@salesforce/label/c.X25";
import X5 from "@salesforce/label/c.X5";
import X50 from "@salesforce/label/c.X50";
import X6 from "@salesforce/label/c.X6";
import Yes from "@salesforce/label/c.Yes";
import No from "@salesforce/label/c.No";
import customCSS from '@salesforce/resourceUrl/customcss';
import Feature_Access_Restricted from '@salesforce/label/c.Feature_Access_Restricted';
import { loadStyle } from 'lightning/platformResourceLoader';

const FILE_LIMIT = "File_Limit";
const UPLOAD_SIZE_LIMIT = "Upload_Size_Limit";
const FILE_PRIVILEGES = "File_Privileges";
const CLEAR_RECYCLE_BIN_IN = "Clear_Recycle_Bin_In";
const RECYCLE_BIN = "Recycle_Bin";
const LOG_ACTIVITY = "Log_Activity";
const RESTRICT_FILE_TYPES = "Restrict_File_Types";

export default class OrgWideConfigurations extends NavigationMixin(LightningElement) {

    @track strSelectedUploadCountLabel;
    //@track strSelectedUploadCountValue = '5';

    @track strSelectedSizeLabel;
    //@track strSelectedSizeValue = '5';

    @track strSelectedFileLimit;
    @track strSelectedSizeLimit;
    @track strselectedFilePrevileges;
    @track strselectedLogActivities;
    @track strselectedFileTypes;
    @track bolSelectedBinReset;
    @track bolSelectedBinResetOld;
    @track mapConfig = new Map();
    @track arrFileTypeOptions = [];
    @track arrConfigs = [];
    @track arrAvailableObject = [];
    @track strselectedBinLimit = '';
    bolSpinner = false;
    bolSave = false;

    bolView = false;
    bolUpload = false;
    bolDownload = false;
    bolPreview = false;
    bolEdit = false;
    bolDelete = false;
    bolIsRecycleBinAllowed = false; // To track if recycle bin feature is allowed
    bolIsFileSizeRestricted = false; // To track the file size restriction
    bolIsUploadSizeRestricted = false; // To track the file upload restriction

    // Custom Labels
    CUSTOM_LABELS = {
        ACTIVE,
        Feature_Access_Restricted, // Helper message 
        INACTIVE,
        Days_FileTranz,
        Maintain_Deleted_Files,
        Option_Enabled,
        Select_Orgwide,
        Files_Uploaded,
        A_maximum_of,
        Select_Specification,
        Save,
        Cancel,
        File_Specifications,
        File_Limit,
        File_Size_Limit_Help_text,
        Selected_Actions,
        Available_Actions,
        Selected_Types,
        Available_Types,
        Log_Activity,
        UPLOAD,
        PREVIEW,
        Download,
        EDIT,
        Delete,
        VIEW,
        The_settings_are_updated_sucessfully,
        Something_went_wrong,
        Org_Wide_Configuration,
        Org_Wide_Configuration_help_text,
        Success,
        Error,
        X6,
        X5,
        X25,
        X200,
        X150,
        X15,
        X100,
        X10,
        X50,
        Loading,
        Yes,
        No,
        Recycle_Bin,
        Maximum_File_Size,
        Maximum_File_Size_Description,
        Max_File_Limit,
        Maximum_File_Limit_Description
    };

    get arrLogActivitiesOptions() {
        return [
            { label: UPLOAD, value: 'Upload' },
            { label: Download, value: 'Download' },
            { label: EDIT, value: 'Edit' },
            { label: Delete, value: 'Delete' }
        ];
    }

    //The below method is to fetch all the object name that are available
    @wire(fetchAllObjectName)
    wiredAllObjectName({ error, data }) {
        if (data) {
            this.arrAvailableObject = data;
        } else if (error) {
            this.showNotification(Error, error.message, 'error');
        }
    }

    connectedCallback() {
        console.log('OrgwideconnectedCallback')
        // 1. Get configurations
        this.getConfigurations();


        setFileSizeLimits()
            .then((result) => {
                this.bolIsFileSizeRestricted = result;
            })
            .catch((error) => {
                this.bolIsFileSizeRestricted = false;
            });

        setFileUploadLimits()
            .then((result) => {
                this.bolIsUploadSizeRestricted = result;
            })
            .catch((error) => {
                this.bolIsUploadSizeRestricted = false;
            });

        isRecycleBinAllowed()
            .then((result) => {
                this.bolIsRecycleBinAllowed = result;
            })
            .catch((error) => {
                this.bolIsRecycleBinAllowed = false;
            });
    }

    bolIsSizeDropdownOpen = false;
    bolIsUploadCountDropdownOpen = false;

   
    strSelectedSizeLimit = '5';
    strSelectedUploadCountLabel = '5';

    toggleDropdown(dropdownProp) {
        this[dropdownProp] = !this[dropdownProp];
    }

    handleOptionSelect(event, config) {
        console.log('event::', JSON.stringify(event));
        console.log('event::', event.detail.value);
         console.log('config::', JSON.stringify(config));
        const value =  event.detail.value;
        const option = config.options.find(o => o.value === value);

        this.bolSave = true;

        if (option.disabled) {
            return;
        }

        this[config.valueProp] = value;
        this[config.labelProp] = option.label;
        this.mapConfig.set(config.configKey, value);
        this[config.dropdownProp] = false;
    }

    getComboboxClass(isOpen) {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${isOpen ? 'slds-is-open' : ''}`;
    }

    toggleSizeDropdown() {
        event.stopPropagation();
        this.toggleDropdown('bolIsSizeDropdownOpen');
    }

    handleSizeSelect(event) {
        this.handleOptionSelect(event, {
            options: this.arrUploadSizeLimitOptions,
            valueProp: 'strSelectedSizeLimit',
            labelProp: 'strSelectedSizeLabel',
            dropdownProp: 'bolIsSizeDropdownOpen',
            configKey: UPLOAD_SIZE_LIMIT
        });
    }

    get fileSizeComboboxClass() {
        return this.getComboboxClass(this.bolIsSizeDropdownOpen);
    }

    // Upload Count Limit Options
    toggleUploadCountDropdown() {
        event.stopPropagation();
        this.toggleDropdown('bolIsUploadCountDropdownOpen');
    }

    handleUploadCountSelect(event) {
        this.handleOptionSelect(event, {
            options: this.arrFileLimitOptions,
            valueProp: 'strSelectedFileLimit',
            labelProp: 'strSelectedUploadCountLabel',
            dropdownProp: 'bolIsUploadCountDropdownOpen',
            configKey: FILE_LIMIT
        });
    }

    get uploadCountComboboxClass() {
        return this.getComboboxClass(this.bolIsUploadCountDropdownOpen);
    }

    //Options 

    get arrUploadSizeLimitOptions() {
        const options = [
            { label: X5 +' MB', value: '5' },
            { label: X10 +' MB', value: '10' },
            { label: X12 + ' MB', value: '12' },
            { label: X25 +' MB', value: '25' },
            { label: X50 +' MB', value: '50' },
            { label: X100 +' MB', value: '100' },
            { label: X150 +' MB', value: '150' },
            { label: X200 +' MB', value: '200' },
            { label: '250' +' MB', value: '250' },
            { label: '500' +' MB', value: '500' },
            { label: '1 GB', value: '1024' },
            { label: '2 GB', value: '2048' }
        ];

        if (!this.bolIsFileSizeRestricted) {
            return options.map(opt => ({
                ...opt,
                disabled: false,
                class: 'slds-listbox__option slds-media slds-media_small slds-media_center'
            }));
        }

        const maxAllowed = 12;

        return options.map(opt => {
            const disabled = Number(opt.value) > maxAllowed;
            return {
                ...opt,
                disabled,
                class: disabled
                    ? 'slds-listbox__option slds-media slds-media_small slds-media_center slds-disabled'
                    : 'slds-listbox__option slds-media slds-media_small slds-media_center'
            };
        });
    }

    get arrFileLimitOptions() {
        const options = [
            { label: X5, value: '5' },
            { label: X10, value: '10' },
            { label: X15, value: '15' },
        ];

        if (!this.bolIsUploadSizeRestricted) {
            return options.map(opt => ({
                ...opt,
                disabled: false,
                class: 'slds-listbox__option slds-media slds-media_small slds-media_center'
            }));
        }

        const maxAllowed = 5;

        return options.map(opt => {
            const disabled = Number(opt.value) > maxAllowed;
            return {
                ...opt,
                disabled,
                class: disabled
                    ? 'slds-listbox__option slds-media slds-media_small slds-media_center slds-disabled'
                    : 'slds-listbox__option slds-media slds-media_small slds-media_center'
            };
        });
    }

    get disableRecycleBinToggle() {
        return !this.bolIsRecycleBinAllowed;
    }


    renderedCallback() {
        Promise.all([
            loadStyle(this, customCSS)
        ]).then(() => {
        })
            .catch(error => {
                console.log(error.body.message);
            })
    }

    // To query configuration records which are all already configured.
    getConfigurations() {
        this.bolSpinner = true;
        getConfigurations()
            .then((result) => {
                this.arrFileTypeOptions = [];
                this.strSelectedFileLimit = result[FILE_LIMIT];
                this.strSelectedSizeLimit = result[UPLOAD_SIZE_LIMIT];
                //this.strselectedFilePrevileges = result[FILE_PRIVILEGES].split('; ');
                this.strSelectedFilePrevileges = (result[FILE_PRIVILEGES] || '').split('; '); // corrected line
                this.strselectedBinLimit = result[CLEAR_RECYCLE_BIN_IN];
                this.bolSelectedBinResetOld = String(result[RECYCLE_BIN] || '').toLowerCase() === 'true'; //---> Corrected line for
                this.bolSelectedBinReset = String(result[RECYCLE_BIN] || '').toLowerCase() === 'true'; //---> Corrected line for
                //this.bolSelectedBinResetOld = result[RECYCLE_BIN].toLowerCase() == 'true';
                //this.bolSelectedBinReset = result[RECYCLE_BIN].toLowerCase() == 'true';
                //this.strselectedLogActivities = result[LOG_ACTIVITY].split('; ');
                this.strSelectedLogActivities = (result[LOG_ACTIVITY] || '').split('; ');  // corrected line
                //this.strselectedFileTypes = result[RESTRICT_FILE_TYPES].split('; ').sort();
                this.strselectedFileTypes = (result[RESTRICT_FILE_TYPES] || '').split('; ').sort(); // corrected line
                //let arrFileType = result["File_Types"].split('; ');
                let arrFileType = (result["File_Types"] || '').split('; '); // corrected line
                for (let i = 0; i < arrFileType.length; i++) {
                    let objPicklistitem = {
                        label: arrFileType[i],
                        value: arrFileType[i]
                    };
                    this.arrFileTypeOptions.push(objPicklistitem);
                }
                this.bolSpinner = false;

                //let arrFileAccess = result["OWD"].split('; ');
                let arrFileAccess = (result["OWD"] || '').split('; '); // corrected line
                this.bolView = arrFileAccess.includes("View");
                this.bolUpload = arrFileAccess.includes("Upload");
                this.bolDownload = arrFileAccess.includes("Download");
                this.bolPreview = arrFileAccess.includes("Preview");
                this.bolEdit = arrFileAccess.includes("Edit");
                this.bolDelete = arrFileAccess.includes("Delete");
            })
            .catch((error) => {
                this.bolSpinner = false;
                this.showNotification(Error, error.message, 'error');
            });
    }

    // To handle input change logics
    handleOnChange(event) {

        this.bolSave = true;
        switch (event.currentTarget.dataset.name) {
            case FILE_LIMIT:
                this.strSelectedFileLimit = event.detail.value;
                this.mapConfig.set(event.currentTarget.dataset.name, this.strSelectedFileLimit);
                break;
            case UPLOAD_SIZE_LIMIT:
                this.strSelectedSizeLimit = event.detail.value;
                this.mapConfig.set(event.currentTarget.dataset.name, this.strSelectedSizeLimit);
                break;
            case FILE_PRIVILEGES:
                this.mapConfig.set(event.currentTarget.dataset.name, this.strselectedFilePrevileges.join("; "));
                break;
            case CLEAR_RECYCLE_BIN_IN:
                this.strselectedBinLimit = event.detail.value;
                this.mapConfig.set(event.currentTarget.dataset.name, this.strselectedBinLimit);

                break;
            case RECYCLE_BIN:
                this.bolSelectedBinReset = event.target.checked;
                if (this.bolSelectedBinResetOld && !this.bolSelectedBinReset) {
                    this.bolDelete = true;
                } else {
                    this.mapConfig.set('Clear_Recycle_Bin_In', 0);
                }
                this.mapConfig.set(event.currentTarget.dataset.name, this.bolSelectedBinReset);
                break;
            case LOG_ACTIVITY:
                this.strselectedLogActivities = event.detail.value;
                this.mapConfig.set(event.currentTarget.dataset.name, this.strselectedLogActivities.join("; "));
                break;
            case RESTRICT_FILE_TYPES:
                this.strselectedFileTypes = event.detail.value.sort();
                this.mapConfig.set(event.currentTarget.dataset.name, this.strselectedFileTypes.join("; "));
                break;
            default:
        }

    }


    // To handle submit logics
    handleSave() {
        let isSave = this.bolSelectedBinReset == true ? this.template.querySelector('.lastNDays').reportValidity() : true;
        if (isSave) {
            if ((this.strselectedBinLimit >= 1 && this.strselectedBinLimit <= 365 && this.bolSelectedBinReset == true) || this.bolSelectedBinReset == false) {
                this.bolSpinner = true;
                for (let [key, value] of this.mapConfig) {
                    let objConfig = {
                        key: key,
                        value: value
                    };
                    this.arrConfigs.push(objConfig);
                }

                updateConfigurations({ lstConfiguration: this.arrConfigs })
                    .then((result) => {
                        if (result == this.CUSTOM_LABELS.Success) {
                            this.showNotification(Success, The_settings_are_updated_sucessfully, 'success');
                            this.bolSave = false;
                            this.bolSpinner = false;
                            this.arrConfigs = [];
                            this.mapConfig.clear();
                            this.getConfigurations();
                        } else {
                            this.showNotification(Error, Something_went_wrong, 'error');
                            this.arrConfigs = [];
                            this.bolSpinner = false;
                        }
                    })
                    .catch((error) => {
                        this.bolSpinner = false;
                        this.arrConfigs = [];
                        this.showNotification(Error, error.message, 'error');
                    });
                this.bolSpinner = false;
            } else {
                this.strselectedBinLimit = 0;
                this.mapConfig.set('Clear_Recycle_Bin_In', 0);
                this.arrConfigs = [];
                this.showNotification('Warning', 'Please enter a valid number of days between 1 and 365 to proceed.', 'warning');
            }
        }
    }

    // To handle cancel logics
    handleCancel() {
        this.getConfigurations();
        this.mapConfig.clear();
        this.bolSave = false;
    }

    // Generic toast method
    showNotification(strTitle, strMessage, strType) {
        let strMode = strType == "error" ? "sticky" : "dismissable";

        const objToastEvent = new ShowToastEvent({
            title: strTitle,
            message: strMessage,
            variant: strType,
            mode: strMode
        });
        this.dispatchEvent(objToastEvent);
    }
    // To handle Inactive toggle
    hideInactiveModal() {
        this.bolDelete = false;
        this.bolSelectedBinReset = !this.bolSelectedBinReset;
        this.mapConfig.set('Recycle_Bin', this.bolSelectedBinReset);
    }
    handleConfirmInactive() {
        this.bolDelete = false;
        this.mapConfig.set('Clear_Recycle_Bin_In', 0);
    }


}