/*
 * Purpose : To configure storage connection details.
 * Author  : Nishanth S
 */
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {LightningElement,track} from "lwc";
// Importing Apex Methods
import createUpdateExtStorageSetting from '@salesforce/apex/StorageConfigurationsController.createUpdateExtStorageSetting';
import fetchAllStorageConfig from '@salesforce/apex/StorageConfigurationsController.getAllStorageConfig';
import validateconnection from '@salesforce/apex/StorageConfigurationsController.validateConnection';
// Importing Static Resurces
import IMAGES from "@salesforce/resourceUrl/FTstaticResource";
import filetranzcustomstyle from "@salesforce/resourceUrl/filetranzcustomstyle";
// Import the Platform Events
import {loadStyle} from "lightning/platformResourceLoader";
// Importing Custom Labels 
import AWS from "@salesforce/label/c.AWS";
import Admin_Access_key_ID from "@salesforce/label/c.Admin_Access_key_ID";
import Admin_Secret_Access_key from "@salesforce/label/c.Admin_Secret_Access_key";
import Amazon_S3 from "@salesforce/label/c.Amazon_S3";
import Bucket from "@salesforce/label/c.Bucket";
import Cancel from "@salesforce/label/c.Cancel";
import Client_ID from "@salesforce/label/c.Client_ID";
import Client_Secret from "@salesforce/label/c.Client_Secret";
import Connection_is_Created_successfully from "@salesforce/label/c.Connection_is_Created_successfully";
import Connection_is_updated_successfully from "@salesforce/label/c.Connection_is_updated_successfully";
import Default_Active_Storage_Connection from "@salesforce/label/c.Default_Active_Storage_Connection";
import Delete from "@salesforce/label/c.Delete";
import Delete_Confirmation from "@salesforce/label/c.Delete_Confirmation";
import EDIT from "@salesforce/label/c.EDIT";
import Edit_configuration from "@salesforce/label/c.Edit_configuration";
import Endpoint_Url from "@salesforce/label/c.Endpoint_Url";
import Enter_AWS_Bucket_Name from "@salesforce/label/c.Enter_AWS_Bucket_Name";
import Enter_AWS_Endpoint_URL from "@salesforce/label/c.Enter_AWS_Endpoint_URL";
import Enter_Access_Key_ID from "@salesforce/label/c.Enter_Access_Key_ID";
import Enter_Connection_Name from "@salesforce/label/c.Enter_Connection_Name";
import Enter_Secret_key_ID from "@salesforce/label/c.Enter_Secret_key_ID";
import Error from "@salesforce/label/c.Error";
import Error_Check_credential from "@salesforce/label/c.Error_Check_credential";
import External_Storage from "@salesforce/label/c.External_Storage";
import Google_Drive from "@salesforce/label/c.Google_Drive";
import Google_Drive_Upcoming_Release from "@salesforce/label/c.Google_Drive_Upcoming_Release";
import Manage_Recycle_Bin from "@salesforce/label/c.Manage_Recycle_Bin";
import Manage_Storage from "@salesforce/label/c.Manage_Storage";
import Name from "@salesforce/label/c.Name";
import One_Drive from "@salesforce/label/c.One_Drive";
import One_Drive_Upcoming_Release from "@salesforce/label/c.One_Drive_Upcoming_Release";
import Org_connection_warning from "@salesforce/label/c.Org_connection_warning";
import Org_wide_Add_Storge_Help_text from "@salesforce/label/c.Org_wide_Add_Storge_Help_text";
import PREVIEW from "@salesforce/label/c.PREVIEW";
import Please_click_and_hold_to_see_the_Secret_key from "@salesforce/label/c.Please_click_and_hold_to_see_the_Secret_key";
import Proceed_To_Submit from "@salesforce/label/c.Proceed_To_Submit";
import Region from "@salesforce/label/c.Region";
import Requied_field_error_message from "@salesforce/label/c.Requied_field_error_message";
import STORAGE_NAME from "@salesforce/label/c.STORAGE_NAME";
import Save from "@salesforce/label/c.Save";
import Select_Region from "@salesforce/label/c.Select_Region";
import Select_the_external_storage from "@salesforce/label/c.Select_the_external_storage";
import Select_the_region from "@salesforce/label/c.Select_the_region";
import Storage_Configuration from "@salesforce/label/c.Storage_Configuration";
import Storage_Configuration_help_text from "@salesforce/label/c.Storage_Configuration_help_text";
import Storage_Name_Default from "@salesforce/label/c.Storage_Name_Default";
import Submit from "@salesforce/label/c.Submit";
import Success from "@salesforce/label/c.Success";
import Successfully_Created from "@salesforce/label/c.Successfully_Created";
import Successfully_Deactivated from "@salesforce/label/c.Successfully_Deactivated";
import Successfully_deleted from "@salesforce/label/c.Successfully_deleted";
import Upcoming_release_text from "@salesforce/label/c.Upcoming_release_text";
import Update from "@salesforce/label/c.Update";
import View from "@salesforce/label/c.VIEW";
import Validate from "@salesforce/label/c.Validate";
import Validation_Completed_msg from "@salesforce/label/c.Validation_Completed_msg";
import Validation_Error from "@salesforce/label/c.Validation_Error";
import Validation_Success from "@salesforce/label/c.Validation_Success";
import View_configuration from "@salesforce/label/c.View_configuration";
import Warning from "@salesforce/label/c.Warning";
import Loading from "@salesforce/label/c.Loading";
import DEFAULT_STORAGE  from "@salesforce/label/c.DEFAULT_STORAGE";



export default class StorageConfigurations extends NavigationMixin(LightningElement) {
    strAWSiconUrl = IMAGES + '/FTstaticResource/awsS3_logo.svg';

    //Custom label 
    CUSTOM_LABELS = {
        Manage_Recycle_Bin,
        Org_wide_Add_Storge_Help_text,
        STORAGE_NAME,
        DEFAULT_STORAGE,
        Storage_Name_Default,
        EDIT,
        Delete,
        Default_Active_Storage_Connection,
        Region,
        Bucket,
        External_Storage,
        Select_the_external_storage,
        Save,
        Cancel,
        Name,
        Admin_Access_key_ID,
        Admin_Secret_Access_key,
        Please_click_and_hold_to_see_the_Secret_key,
        Select_Region,
        Select_the_region,
        Endpoint_Url,
        Org_connection_warning,
        Proceed_To_Submit,
        Validate,
        Submit,
        Edit_configuration,
        Update,
        View_configuration,
        Upcoming_release_text,
        View,
        Validation_Completed_msg,
        Error_Check_credential,
        Storage_Configuration,
        Storage_Configuration_help_text,
        Manage_Storage,
        Amazon_S3,
        One_Drive_Upcoming_Release,
        Google_Drive_Upcoming_Release,
        One_Drive,
        Delete_Confirmation,
        AWS,
        Google_Drive,
        Enter_Access_Key_ID,
        Enter_AWS_Bucket_Name,
        Enter_AWS_Endpoint_URL,
        Enter_Connection_Name,
        Enter_Secret_key_ID,
        Warning,
        PREVIEW,
        Client_ID,
        Client_Secret,
        Connection_is_Created_successfully,
        Connection_is_updated_successfully,
        Successfully_Deactivated,
        Successfully_Created,
        Success,
        Error,
        Successfully_deleted,
        Validation_Success,
        Validation_Error,
        Loading
    };

    //Boolean declarations
    bolAmazonS3 = false;
    bolOneDrive = false;
    bolGoogleDrive = false;
    bolSpinner = false;
    bolNoDefaultStorage = false;
    bolValidated = false;
    bolNewConfig = false;

    //Array declaration
    @track arrStorageData = [];

    //String declaration
    strExtStorageName;
    @track strInputTypeSecretKey = 'password';

    //object declaration
    @track objWrapperExterStorageSetting = {};

    get bolDisableSubmit() {
        return !this.bolValidated;
    }

    // Storage that are included for the connection
    get arrAvailRegions() {
        return [{
                label: 'us-east-1',
                value: 'us-east-1'
            },
            {
                label: 'us-east-2',
                value: 'us-east-2'
            },
            {
                label: 'us-west-1',
                value: 'us-west-1'
            },
            {
                label: 'us-west-2',
                value: 'us-west-2'
            },
            {
                label: 'af-south-1',
                value: 'af-south-1'
            },
            {
                label: 'ap-east-1',
                value: 'ap-east-1'
            },
            {
                label: 'ap-south-2',
                value: 'ap-south-2'
            },
            {
                label: 'ap-southeast-3',
                value: 'ap-southeast-3'
            },
            {
                label: 'ap-southeast-4',
                value: 'ap-southeast-4'
            },
            {
                label: 'ap-south-1',
                value: 'ap-south-1'
            },
            {
                label: 'ap-northeast-3',
                value: 'ap-northeast-3'
            },
            {
                label: 'ap-northeast-2',
                value: 'ap-northeast-2'
            },
            {
                label: 'ap-southeast-1',
                value: 'ap-southeast-1'
            },
            {
                label: 'ap-southeast-2',
                value: 'ap-southeast-2'
            },
            {
                label: 'ap-northeast-1',
                value: 'ap-northeast-1'
            },
            {
                label: 'ca-central-1',
                value: 'ca-central-1'
            },
            {
                label: 'eu-central-1',
                value: 'eu-central-1'
            },
            {
                label: 'eu-west-1',
                value: 'eu-west-1'
            },
            {
                label: 'eu-west-2	',
                value: 'eu-west-2'
            },
            {
                label: 'eu-south-1',
                value: 'eu-south-1'
            },
            {
                label: 'eu-west-3	',
                value: 'eu-west-3'
            },
            {
                label: 'eu-south-2',
                value: 'eu-south-2'
            },
            {
                label: 'eu-north-1',
                value: 'eu-north-1'
            },
            {
                label: 'eu-central-2',
                value: 'eu-central-2'
            },
            {
                label: 'il-central-1',
                value: 'il-central-1'
            },
            {
                label: 'me-south-1',
                value: 'me-south-1'
            },
            {
                label: 'me-central-1',
                value: 'me-central-1'
            },
            {
                label: 'sa-east-1',
                value: 'sa-east-1'
            },
            {
                label: 'us-gov-east-1',
                value: 'us-gov-east-1'
            },
            {
                label: 'us-gov-west-1',
                value: 'us-gov-west-1'
            },
        ];
    }

    connectedCallback() {
        //Call the handleGetStorageConfiguration method
        this.handleGetStorageConfiguration();
        loadStyle(this, filetranzcustomstyle);
    }

    renderedCallback() {
        window.scrollTo(0, 0);
    }

    // To get the storage configuration records.
    handleGetStorageConfiguration() {
        fetchAllStorageConfig()
            .then(result => {
                this.arrStorageData = result;
                this.bolNoDefaultStorage = true;
                if (this.arrStorageData.length > 0) {
                    Object.assign(this.objWrapperExterStorageSetting, this.arrStorageData[0]);
                    this.bolNewConfig = false;
                    this.bolNoDefaultStorage = false;
                } else {
                    this.bolNewConfig = true;
                }
                this.bolSpinner = false;
            })
            .catch(error => {
                this.bolSpinner = false;
            });
    }

    //Te below method is to handle the value that are changed at the time of creating and updating connection
    async handleValueChange(event) {
        this.bolSpinner = true;
        this.bolValidated = false;
        try {
            this.objWrapperExterStorageSetting[event.target.name] = event.target.value;
            this.bolSpinner = false;
        } catch (err) {
            this.bolSpinner = false;
        }
    }


    //Te below method is to perform validation for the connection
    handleConnectionValidation() {
        let strResult = this.handleValueValidation(this.objWrapperExterStorageSetting);
        if (strResult === Validation_Success) {
            this.bolSpinner = true;
            validateconnection({
                    strExtStorageSet: JSON.stringify(this.objWrapperExterStorageSetting)
                })
                .then(result => {
                    this.bolSpinner = false;
                    if (result === '200') {
                        this.handleNotification(Success, Validation_Completed_msg);
                        this.bolValidated = true;
                    } else {
                        this.handleNotification(Error, Error_Check_credential);
                    }
                })
                .catch(error => {
                    console.log(error.message);
                });
        }
    }

    handleValueValidation(objWrapperExterStorageSetting) {
        if (objWrapperExterStorageSetting.strAccKy === '' || objWrapperExterStorageSetting.strAccKy === undefined || objWrapperExterStorageSetting.strStKey === '' || objWrapperExterStorageSetting.strStKey === undefined ||
            objWrapperExterStorageSetting.strRegion === '' || objWrapperExterStorageSetting.strRegion === undefined || objWrapperExterStorageSetting.strEndPoint === '' ||
            objWrapperExterStorageSetting.strEndPoint === undefined || objWrapperExterStorageSetting.strBucket === '' || objWrapperExterStorageSetting.strBucket === undefined) {
            this.handleNotification(Error, Requied_field_error_message);
            return Validation_Error;
        } else {
            return Validation_Success;
        }
    }

    //Te below method is to handle the connection when submit - this Apex call is invoked directly
    //from the Submit button's click handler (not via a helper) so it's unambiguously user-gesture-gated.
    handleConnectionSubmit(event) {
        let strResult = this.handleValueValidation(this.objWrapperExterStorageSetting);
        if (strResult !== Validation_Success) {
            return;
        }
        this.bolSpinner = true;
        let strMessage = event.target.name === Update ? Connection_is_updated_successfully : Connection_is_Created_successfully;
        createUpdateExtStorageSetting({
                strExtStorageSet: JSON.stringify(this.objWrapperExterStorageSetting),
                strObjects: this.objWrapperExterStorageSetting.strObjects
            })
            .then(result => {
                if (result === Successfully_Created) {
                    this.handleNotification(Success, strMessage);
                    this.bolEditConfigModal = false;
                    this.bolCreateConfigModal = false;
                    this.handleGetStorageConfiguration();
                    this.objWrapperExterStorageSetting = {};
                    this.bolValidated = false;
                } else {
                    this.handleNotification(Error, Successfully_Created);
                }
                this.bolSpinner = false;
            })
            .catch(error => {
                this.bolSpinner = false;
            });
    }

    // The below two consecutive method is to handle the text masking and unmasking 
    handleEyeIconIn() {
        this.strInputTypeSecretKey = 'text';
    }

    handleEyeIconOut() {
        this.strInputTypeSecretKey = 'password';
    }

    //The below method is to handle the notification 
    handleNotification(strVariant, strMessage) {
        const objToastEvent = new ShowToastEvent({
            title: strVariant,
            message: strMessage,
            variant: strVariant
        });
        this.dispatchEvent(objToastEvent);
    }
}