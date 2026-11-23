/*
 * Purpose : Screen for setup/monitor/run filetranz batch/scheduled jobs.
 * Author  : Anandhakumar Thangasamy
 */

import { refreshApex } from "@salesforce/apex";
import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, track, wire } from "lwc";
// Importing Apex Methods
import getSObjectFields from "@salesforce/apex/CommonUtilities.getSObjectFields";
import abortBatchJob from "@salesforce/apex/JobConfigurationsController.abortBatchJob";
import deleteScheduledJobs from "@salesforce/apex/JobConfigurationsController.deleteScheduledJobs";
import excuteBatchJob from "@salesforce/apex/JobConfigurationsController.excuteBatchJob";
import getJobDetails from "@salesforce/apex/JobConfigurationsController.getJobDetails";
import getRunningBatchStatus from "@salesforce/apex/JobConfigurationsController.getRunningBatchStatus";
import getScheduledJobs from "@salesforce/apex/JobConfigurationsController.getScheduledJobs";
import scheduleJob from "@salesforce/apex/JobConfigurationsController.scheduleJob";
import validateQuery from "@salesforce/apex/JobConfigurationsController.validateQuery";
import logError from "@salesforce/apex/ErrorLogger.logError";
import checkEditionPermission from "@salesforce/apex/JobConfigurationsController.checkEditionPermission";
// Importing Static Resources
import toastCSS from "@salesforce/resourceUrl/toastCSS";
//Importing Custom Labels
import fetchAllObjectName from "@salesforce/apex/CommonUtilities.getAllObjectName";
import ACTION from "@salesforce/label/c.ACTION";
import ACTIVE from "@salesforce/label/c.ACTIVE";
import AND from "@salesforce/label/c.AND";
import Abort from "@salesforce/label/c.Abort";
import Aborted from "@salesforce/label/c.Aborted";
import Add from "@salesforce/label/c.Add";
import Add_conditional_logic_for_all_conditions from "@salesforce/label/c.Add_conditional_logic_for_all_conditions";
import Administrator_can_manage_all_the_Filetranz_Jobs from "@salesforce/label/c.Administrator_can_manage_all_the_Filetranz_Jobs";
import Alert from "@salesforce/label/c.Alert";
import Alert_Message from "@salesforce/label/c.Alert_Message";
import All from "@salesforce/label/c.All";
import Apply_Filter from "@salesforce/label/c.Apply_Filter";
import Attachments from "@salesforce/label/c.Attachments";
import Back_To_Home from "@salesforce/label/c.Back_To_Home";
import Batch_Condition from "@salesforce/label/c.Batch_Condition";
import Batch_Condition_help_text from "@salesforce/label/c.Batch_Condition_help_text";
import Batch_delete_files_help_text from "@salesforce/label/c.Batch_delete_files_help_text";
import Batch_help_text from "@salesforce/label/c.Batch_help_text";
import Batch_include_user_help_text from "@salesforce/label/c.Batch_include_user_help_text";
import Batch_job_will_run_in_the_background_Please_use_the_batch_status_to_monitor_the from "@salesforce/label/c.Batch_job_will_run_in_the_background_Please_use_the_batch_status_to_monitor_the";
import Batches from "@salesforce/label/c.Batches";
import Cannot_abort_a_job_that_is_already_completed from "@salesforce/label/c.Cannot_abort_a_job_that_is_already_completed";
import Close from "@salesforce/label/c.Close";
import Completed from "@salesforce/label/c.Completed";
import Condition from "@salesforce/label/c.Condition";
import Conditional_Logic from "@salesforce/label/c.Conditional_Logic";
import Conditional_Logic_help_text from "@salesforce/label/c.Conditional_Logic_help_text";
import Delete from "@salesforce/label/c.Delete";
import Delete_Original_Attachment_after_upload from "@salesforce/label/c.Delete_Original_Attachment_after_upload";
import Delete_Original_File_after_upload from "@salesforce/label/c.Delete_Original_File_after_upload";
import Do_you_want_to_abort_the_batch_job from "@salesforce/label/c.Do_you_want_to_abort_the_batch_job";
import EXCLUDES from "@salesforce/label/c.EXCLUDES";
import Error from "@salesforce/label/c.Error";
import Execute_Batch from "@salesforce/label/c.Execute_Batch";
import Executing_this_batch_will_upload_all_the_Salesforce_attachments_to_the_External from "@salesforce/label/c.Executing_this_batch_will_upload_all_the_Salesforce_attachments_to_the_External";
import Executing_this_batch_will_upload_all_the_Salesforce_files_to_the_External_Storag from "@salesforce/label/c.Executing_this_batch_will_upload_all_the_Salesforce_files_to_the_External_Storag";
import Executing_this_batch_will_upload_on_the_content_document_link_provided from "@salesforce/label/c.Executing_this_batch_will_upload_on_the_content_document_link_provided";
import Failed from "@salesforce/label/c.Failed";
import Field from "@salesforce/label/c.Field";
import Filter_Criteria from "@salesforce/label/c.Filter_Criteria";
import Frequency from "@salesforce/label/c.Frequency";
import Friday from "@salesforce/label/c.Friday";
import IN from "@salesforce/label/c.IN";
import INACTIVE from "@salesforce/label/c.INACTIVE";
import INCLUDES from "@salesforce/label/c.INCLUDES";
import Include_User_Files from "@salesforce/label/c.Include_User_Files";
import Info from "@salesforce/label/c.Info";
import JOB_NAME from "@salesforce/label/c.JOB_NAME";
import LIKE from "@salesforce/label/c.LIKE";
import Loading from "@salesforce/label/c.Loading";
import Manage_Filetranz_Jobs from "@salesforce/label/c.Manage_Filetranz_Jobs";
import Migrate_Options from "@salesforce/label/c.Migrate_Options";
import Migrate_by_Object from "@salesforce/label/c.Migrate_by_Object";
import Monday from "@salesforce/label/c.Monday";
import Monthly from "@salesforce/label/c.Monthly";
import NEXT_SCHEDULED_RUN from "@salesforce/label/c.NEXT_SCHEDULED_RUN";
import NOT from "@salesforce/label/c.NOT";
import NOT_IN from "@salesforce/label/c.NOT_IN";
import Next from "@salesforce/label/c.Next";
import No from "@salesforce/label/c.No";
import No_jobs_are_selected_to_abort from "@salesforce/label/c.No_jobs_are_selected_to_abort";
import No_jobs_scheduled_at_the_moment from "@salesforce/label/c.No_jobs_scheduled_at_the_moment";
import OR from "@salesforce/label/c.OR";
import On from "@salesforce/label/c.On";
import On_day from "@salesforce/label/c.On_day";
import On_the from "@salesforce/label/c.On_the";
import Once from "@salesforce/label/c.Once";
import Operator from "@salesforce/label/c.Operator";
import Pick_My_Conditions from "@salesforce/label/c.Pick_My_Conditions";
import Please_enter_valid_email_addresses from "@salesforce/label/c.Please_enter_valid_email_addresses";
import Please_populate from "@salesforce/label/c.Please_populate";
import Prefered_time_help_text from "@salesforce/label/c.Prefered_time_help_text";
import Preferred_Schedule_Date from "@salesforce/label/c.Preferred_Schedule_Date";
import Preferred_Start_time from "@salesforce/label/c.Preferred_Start_time";
import Preferred_Time from "@salesforce/label/c.Preferred_Time";
import Previous from "@salesforce/label/c.Previous";
import Recurs_every_week_on from "@salesforce/label/c.Recurs_every_week_on";
import Refresh from "@salesforce/label/c.Refresh";
import Required_fields_are_missing from "@salesforce/label/c.Required_fields_are_missing";
import Run_FileTranz_Job from "@salesforce/label/c.Run_FileTranz_Job";
import Run_Job from "@salesforce/label/c.Run_Job";
import SCHEDULED_BY from "@salesforce/label/c.SCHEDULED_BY";
import SCHEDULED_DATE from "@salesforce/label/c.SCHEDULED_DATE";
import START_TIME from "@salesforce/label/c.START_TIME";
import Saturday from "@salesforce/label/c.Saturday";
import Schedule_Batch from "@salesforce/label/c.Schedule_Batch";
import Schedule_FileTranz_Job from "@salesforce/label/c.Schedule_FileTranz_Job";
import Schedule_Job from "@salesforce/label/c.Schedule_Job";
import Select_Batch from "@salesforce/label/c.Select_Batch";
import Select_the_object from "@salesforce/label/c.Select_the_object";
import Something_went_wrong from "@salesforce/label/c.Something_went_wrong";
import Specific from "@salesforce/label/c.Specific";
import Status from "@salesforce/label/c.Status";
import Success from "@salesforce/label/c.Success";
import Success_message_job_Deleted from "@salesforce/label/c.Success_message_job_Deleted";
import Sunday from "@salesforce/label/c.Sunday";
import Thursday from "@salesforce/label/c.Thursday";
import Tuesday from "@salesforce/label/c.Tuesday";
import Upload_Attachment_batch_help_text from "@salesforce/label/c.Upload_Attachment_batch_help_text";
import Upload_Attachments from "@salesforce/label/c.Upload_Attachments";
import Upload_Files from "@salesforce/label/c.Upload_Files";
import Upload_files_batch_help from "@salesforce/label/c.Upload_files_batch_help";
import Validate from "@salesforce/label/c.Validate";
import Value from "@salesforce/label/c.Value";
import Wednesday from "@salesforce/label/c.Wednesday";
import Weekdays from "@salesforce/label/c.Weekdays";
import Weekly from "@salesforce/label/c.Weekly";
import Write_My_Conditions from "@salesforce/label/c.Write_My_Conditions";
import X1st from "@salesforce/label/c.X1st";
import X2nd from "@salesforce/label/c.X2nd";
import X3rd from "@salesforce/label/c.X3rd";
import X4th from "@salesforce/label/c.X4th";
import Yes from "@salesforce/label/c.Yes";
import You_can_add_upto_9_conditions_only from "@salesforce/label/c.You_can_add_upto_9_conditions_only";
import files from "@salesforce/label/c.files";
import last from "@salesforce/label/c.last";
import of from "@salesforce/label/c.of";
import of_every_month from "@salesforce/label/c.of_every_month";
import success_Message_job_initiated from "@salesforce/label/c.success_Message_job_initiated";
import to_proceed_further from "@salesforce/label/c.to_proceed_further";
import filetranzcustomstyle from "@salesforce/resourceUrl/filetranzcustomstyle";
import LightningAlert from "lightning/alert";
import Preferred_Schedule_Date_Error_Message from "@salesforce/label/c.Preferred_Schedule_Date_Error_Message";
import Confirm_Delete from "@salesforce/label/c.Confirm_Delete";
import Are_you_sure_you_want_to_delete_it from "@salesforce/label/c.Are_you_sure_you_want_to_delete_it";
import Batch_Condition_help_text_CDL from "@salesforce/label/c.Batch_Condition_help_text_CDL";
import Batch_Condition_Help_Text_Attachment from "@salesforce/label/c.Batch_Condition_Help_Text_Attachment";
import Batch_Condition_Help_Text_AttachmentParent from "@salesforce/label/c.Batch_Condition_Help_Text_AttachmentParent";
import Feature_Access_Restricted from "@salesforce/label/c.Feature_Access_Restricted";
import LightningToast from "lightning/toast";


export default class JobConfigurations extends LightningElement {
  @track arrDayOptions = [];
  @track arrScheduledJobs = [];
  @track arrContentDocFields = [];
  @track arrAttachmentFields = [];
  @track arrFieldOptions = [];
  @track arrRunningBatchStatusData = [];
  @track arrConditions = [];
  @track arrAvailableObject = [];
  @track arrContentDocLinkFields = [];
  @track bolSpinner = true;
  @track bolShowOnce = true;
  @track bolShowWeekly = false;
  @track bolShowMonthly = false;
  @track bolIncludeUserRecords = false;
  @track bolDeleteUploadedRecords = false;
  @track bolBatchStatus = false;
  @track bolAttachmentsCheck = false;
  @track bolAttachmentsByObjectCheck = false;
  @track bolFileBatchCDL = false;
  @track bolAllFiles = false;
  @track strObject = "";
  @track strJobDescription = "";
  @track strWhere;
  @track strBatchOption = "Specific";
  @track objScheduleJobWrapper = {};
  @track objExcuteBatchJobWrapper = {};
  @track objLogErrorWrapper = {};
  bolShowHlpText = false; // To show/ hide help text for schedule job button
  bolIsScheduleJobAllowed = false; // To check whether the edition is free or paid
  bolShowScheduleMessage = false; // To show/ hide help text for schedule job button
  strFrequency = "Once";
  strWeekly = "";
  strDay = "1";
  strWeek = "1";
  strWeekDay = "1";
  strLastNdays;
  strBatchType;
  strName;
  strBatchJobId;
  strConditionalLogic = "1";
  strBatchStatus;
  strDeleteHelp = Batch_delete_files_help_text;
  strIncludeUserHelp = Batch_include_user_help_text;
  strBatchHelp = Batch_help_text;
  strUploadFileBatchHelp = Upload_files_batch_help;
  strAttachmentBatchHelp = Upload_Attachment_batch_help_text;
  strLogActivityBatchHelp = "";
  strConditionOption = "Pick";
  strPreferedTimeFieldHelp = Prefered_time_help_text;
  bolShowJobDescription = false;
  bolDayOfMonth = true;
  bolWeekOfMonth = false;
  bolFileBatch = true;
  bolScheduleApex = false;
  bolManualBatchCondition = false;
  bolShowTable = false;
  bolShowBatchConfiguration = false;
  bolRunBatch = false;
  bolBatchJobId = false;
  bolDisableAbort = true;
  bolShowAbortWarning = false;
  intExecutedPercentage;
  bolBatchOption = false;
  tStartDate;
  tStartTime;
  strCurrentStep = "1";
  stateManageJob = {
    bolDisablePrevious: true,
    bolDisableNext: false,
    bolFirstStep: true,
    bolSecondStep: false,
    bolThirdStep: false
  };
  @track strDeleteOriginalFileLabel = Delete_Original_File_after_upload;
  @track strBatchConditionHelpText = Batch_Condition_help_text;
  @track bolDelete = false;
  @track strJobName = '';
  bolValidated = false;
  bolDisableExecute = false;

  get bolPickCondition() {
    return !this.bolManualBatchCondition;
  }

  get bolDisableMigrateOption() {
    return this.bolFileBatchCDL || this.bolAttachmentsByObjectCheck;
  }

  get bolShowUserFileIncludeChk() {
    return !this.bolAttachmentsByObjectCheck && !this.bolAttachmentsCheck && !this.bolFileBatchCDL;
  }
  bolSunday = false;
  bolMonday = false;
  bolTuesday = false;
  bolWednesday = false;
  bolThursday = false;
  bolFriday = false;
  bolSatday = false;
  bolEvnt = false;

  //Custom Labels
  @track
  CUSTOM_LABELS = {
    ACTIVE,
    INACTIVE,
    Feature_Access_Restricted, // Helper message
    Next,
    Previous,
    Once,
    Schedule_Batch,
    Apply_Filter,
    Select_Batch,
    Schedule_Job,
    Run_Job,
    JOB_NAME,
    START_TIME,
    NEXT_SCHEDULED_RUN,
    SCHEDULED_DATE,
    SCHEDULED_BY,
    ACTION,
    Delete,
    Refresh,
    Status,
    Batches,
    Condition,
    Delete_Original_File_after_upload,
    Include_User_Files,
    Frequency,
    Recurs_every_week_on,
    On_day,
    On_the,
    of,
    Preferred_Start_time,
    Preferred_Schedule_Date,
    Execute_Batch,
    of_every_month,
    Run_FileTranz_Job,
    Upload_Attachments,
    Sunday,
    Saturday,
    Monthly,
    Monday,
    Tuesday,
    Thursday,
    Friday,
    Wednesday,
    Weekly,
    Something_went_wrong,
    No_jobs_are_selected_to_abort,
    Required_fields_are_missing,
    Please_populate,
    to_proceed_further,
    On,
    Upload_Files,
    Manage_Filetranz_Jobs,
    Administrator_can_manage_all_the_Filetranz_Jobs,
    Migrate_Options,
    Filter_Criteria,
    Batch_Condition,
    Select_the_object,
    Value,
    Operator,
    Field,
    Add,
    Conditional_Logic,
    Conditional_Logic_help_text,
    Batch_Condition_help_text,
    Close,
    Validate,
    Abort,
    Do_you_want_to_abort_the_batch_job,
    Yes,
    No,
    Pick_My_Conditions,
    All,
    Specific,
    Write_My_Conditions,
    Error,
    last,
    Success,
    NOT,
    OR,
    AND,
    EXCLUDES,
    INCLUDES,
    LIKE,
    NOT_IN,
    IN,
    X4th,
    X3rd,
    X2nd,
    X1st,
    You_can_add_upto_9_conditions_only,
    Executing_this_batch_will_upload_on_the_content_document_link_provided,
    Executing_this_batch_will_upload_all_the_Salesforce_attachments_to_the_External,
    Executing_this_batch_will_upload_all_the_Salesforce_files_to_the_External_Storag,
    Please_enter_valid_email_addresses,
    Add_conditional_logic_for_all_conditions,
    Info,
    Preferred_Time,
    Weekdays,
    Failed,
    Completed,
    Aborted,
    Attachments,
    files,
    Loading,
    Schedule_FileTranz_Job,
    Back_To_Home,
    Migrate_by_Object,
    Success_message_job_Deleted,
    Confirm_Delete,
    Are_you_sure_you_want_to_delete_it,
    Batch_Condition_help_text_CDL,
    Batch_Condition_Help_Text_Attachment,
    Batch_job_will_run_in_the_background_Please_use_the_batch_status_to_monitor_the,
    success_Message_job_initiated,
    Preferred_Schedule_Date_Error_Message,
    Batch_Condition_Help_Text_AttachmentParent,
    Delete_Original_Attachment_after_upload,
    No_jobs_scheduled_at_the_moment
  };
  get bolShowDel() {
    return this.arrConditions.length > 1 ? true : false;
  }
  get bolShowBatchOption() {
    return (
      !this.bolAllFiles ||
      this.bolFileBatchCDL ||
      this.bolAttachmentsByObjectCheck
    );
  }
  get strLabel() {
    return this.bolFileBatch ? " " + files : " " + Attachments;
  }
  get optionsFrequency() {
    return [
      { label: Weekly, value: "Weekly" },
      { label: Monthly, value: "Monthly" }
    ];
  }
  get arrConditionOptions() {
    return [
      { label: Pick_My_Conditions, value: "Pick" },
      { label: Write_My_Conditions, value: "Manually" }
    ];
  }
  get arrBatchOptions() {
    return [
      { label: All + this.strLabel, value: "All" },
      { label: Specific + this.strLabel, value: "Specific" }
    ];
  }
  get arrWeekOptions() {
    return [
      { label: X1st, value: "1" },
      { label: X2nd, value: "2" },
      { label: X3rd, value: "3" },
      { label: X4th, value: "4" },
      { label: last, value: "L" }
    ];
  }
  get arrWeekDayOptions() {
    return [
      { label: Sunday, value: "SUN" },
      { label: Monday, value: "MON" },
      { label: Tuesday, value: "TUE" },
      { label: Wednesday, value: "WED" },
      { label: Thursday, value: "THU" },
      { label: Friday, value: "FRI" },
      { label: Saturday, value: "SAT" }
    ];
  }
  get optionsMonthly() {
    return [{ label: On_day, value: "On day" }, { label: On, value: "On" }];
  }
  get arrOperators() {
    return [
      { label: "=", value: "=" },
      { label: "!=", value: "!=" },
      { label: "<", value: "<" },
      { label: ">", value: ">" },
      { label: ">=", value: ">=" },
      { label: "<=", value: "<=" },
      { label: IN, value: "IN" },
      { label: NOT_IN, value: "NOT IN" },
      { label: LIKE, value: "LIKE" },
      { label: INCLUDES, value: "INCLUDES" },
      { label: EXCLUDES, value: "EXCLUDES" }
    ];
  }
  get arrLogicalOperators() {
    return [
      { label: AND, value: "AND" },
      { label: OR, value: "OR" },
      { label: NOT, value: "NOT" }
    ];
  }

  // To get all object names
  @wire(fetchAllObjectName)
  wiredAllObjectName({ error, data }) {
    if (data) {
      this.arrAvailableObject = data;
    } else if (error) {
      this.showNotification(Error, error.message, "Error");
    }
  }
  // To get the FileTranz batch results
  @wire(getRunningBatchStatus)
  wiredallRunningBatch(result) {
    this.bolSpinner = true;
    this.wiredallRunningBatchData = result;
    if (result.data) {
      this.arrRunningBatchStatusData = result.data;
      if (this.arrRunningBatchStatusData.length == 0) {
        this.bolBatchStatus = true;
      }
      this.bolSpinner = false;
    } else if (result.error) {
      this.bolSpinner = false;
      this.showNotification(Error, result.error, "Error");
    }
  }

  // connectedCallback logics
  connectedCallback() {
    loadStyle(this, filetranzcustomstyle);
    this.handleAddRow();
    this.bolSpinner = true;
    for (let j = 1; j <= 31; j++) {
      let objPicklistitem = {
        label: j.toString(),
        value: j.toString()
      };
      this.arrDayOptions.push(objPicklistitem);
    }
    this.arrDayOptions.push({
      label: last,
      value: "L"
    });
    this.getScheduledApexJobs();
    this.getContentDocumentFields();
    this.getAttachmentFields();
    this.checkEditionPermissions();
  }

  handleBackToHome() {
    this.bolShowBatchConfiguration = false;
    this.hideBatchModalBox();
  }

  handleNext() {
    this.stateManageJob.bolDisableNext = false;
    this.stateManageJob.bolDisablePrevious = false;
    if (this.strCurrentStep == "1") {
      if (
        (this.strName === undefined || this.strName === "") &&
        !this.bolRunBatch
      ) {
        this.showNotification(
          Required_fields_are_missing,
          Please_populate + " " + JOB_NAME + " " + to_proceed_further,
          "error"
        );
      } else {
        this.handleAlertClick();
        this.strCurrentStep = "2";
      }
    } else if (this.strCurrentStep == "2" && !this.bolRunBatch) {
      const bolValid = [
        ...this.template.querySelectorAll(".reqValidation")
      ].reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
      }, true);
      let bolEmailValid = true;
      if (bolValid) {

        if (bolEmailValid) {
          this.strCurrentStep = "3";
          this.stateManageJob.bolDisableNext = true;
          if (this.bolShowOnce == true) {
            this.bolShowWeekly = false;
            this.bolShowMonthly = false;
            this.bolShowOnce = true;
          } else if (this.bolShowWeekly == true) {
            this.bolShowWeekly = true;
            this.bolShowMonthly = false;
            this.bolShowOnce = false;
          } else {
            this.bolShowWeekly = false;
            this.bolShowMonthly = true;
            this.bolShowOnce = false;
          }
        } else {
          this.showNotification(Error, Please_enter_valid_email_addresses, "Error");
        }
      }
    }
    this.handleCurrentStep();
  }


  handlePrevious() {
    this.stateManageJob.bolDisableNext = false;
    this.stateManageJob.bolDisablePrevious = false;
    if (this.strCurrentStep == "2") {
      this.strCurrentStep = "1";
      this.stateManageJob.bolDisablePrevious = true;
    } else if (this.strCurrentStep == "3") {
      this.strCurrentStep = "2";

    }

    this.handleCurrentStep();
  }

  handleCurrentStep() {
    if (this.strCurrentStep == "1") {
      this.stateManageJob.bolFirstStep = true;
      this.stateManageJob.bolSecondStep = false;
      this.stateManageJob.bolThirdStep = false;
    } else if (this.strCurrentStep == "2") {
      this.stateManageJob.bolFirstStep = false;
      this.stateManageJob.bolSecondStep = true;
      this.stateManageJob.bolThirdStep = false;
    } else if (this.strCurrentStep == "3") {
      this.stateManageJob.bolFirstStep = false;
      this.stateManageJob.bolSecondStep = false;
      this.stateManageJob.bolThirdStep = true;
    }

  }

  // To set CSS from static resource
  renderedCallback() {
    loadStyle(this, toastCSS).then(() => { }).catch(error => {
      this.showNotification(Error, error.message, "Error");
    });

    //window.scrollTo(0, 0);
  }

  // To get the scheduled FileTranz jobs details
  getScheduledApexJobs() {
    getScheduledJobs()
      .then(result => {
        this.arrScheduledJobs = result;
        if (this.arrScheduledJobs.length > 0) {
          this.bolShowTable = true;
          this.bolSpinner = false;
        } else if (this.arrScheduledJobs.length == 0) {
          this.bolShowTable = false;
          this.bolSpinner = false;
        }
      })
      .catch(error => {
        this.bolShowTable = false;
        this.showNotification(Error, error.message, "Error");
      });
  }

  // To query ContentDocument fields
  getContentDocumentFields() {
    console.log('getContentDocumentFields');
    getSObjectFields({ strObjectName: "ContentDocument" })
      .then(result => {
        console.log('this.arrFieldOptions:result::', JSON.stringify(result));
        if (result != null) {
          this.arrContentDocFields = result;
          this.arrFieldOptions = [...this.arrContentDocFields];
          console.log('this.arrFieldOptions:::', JSON.stringify(this.arrFieldOptions));
        }
      })
      .catch(error => {
        this.showNotification(Error, error.message, "Error");
      });
  }

  // To query ContentDocumentLink fields
  getContentDocumentLinkFields() {
    getSObjectFields({ strObjectName: this.strObject })
      .then(result => {
        if (result != null) {
          this.arrContentDocLinkFields = result;
          this.arrFieldOptions = [...this.arrContentDocLinkFields];
        }
      })
      .catch(error => {
        this.showNotification(Error, error.message, "Error");
      });
  }

  // To query Attachment fields
  getAttachmentFields() {
    getSObjectFields({ strObjectName: "Attachment" })
      .then(result => {
        if (result != null) {
          this.arrAttachmentFields = result;
        }
      })
      .catch(error => {
        this.showNotification(Error, error.message, "Error");
      });
  }

  // To add a new row in batch/schedule filter screen
  handleAddRow() {
    this.bolSpinner = true;
    if (this.arrConditions.length < 9) {
      let objCondition = {
        key: this.arrConditions.length + 1,
        strField: "",
        strOperator: "",
        strValue: "",
        bolShowAdd: true,
        isRequired: true
      };
      this.arrConditions.push(objCondition);
      if (objCondition.key > 1) {
        this.arrConditions[this.arrConditions.length - 2].bolShowAdd = false;
      }
      this.reorderConditions();
    } else {
      this.showNotification(Error, You_can_add_upto_9_conditions_only, "Error");
    }
    this.bolSpinner = false;
  }

  // To reorder the given conditions while deleting/adding a row in batch/schedule filter screen
  reorderConditions() {
    this.strConditionalLogic = "";
    for (let j = 0; j < this.arrConditions.length; j++) {
      let intTempKey = j + 1;
      this.arrConditions[j].key = intTempKey;
      this.strConditionalLogic =
        this.strConditionalLogic + intTempKey.toString() + " AND ";
      if (j == this.arrConditions.length - 1) {
        this.arrConditions[j].bolShowAdd = true;
      } else {
        this.arrConditions[j].bolShowAdd = false;
      }
    }
    this.strConditionalLogic = this.strConditionalLogic.substring(
      0,
      this.strConditionalLogic.length - 4
    );
  }

  // To delete the given condition in batch/schedule filter screen
  handleConditionDelete(event) {
    this.bolSpinner = true;
    for (let i = 0; i < this.arrConditions.length; i++) {
      if (this.arrConditions[i].key == event.currentTarget.dataset.id) {
        this.arrConditions.splice(i, 1);
        this.reorderConditions();
        break;
      }
    }
    this.bolSpinner = false;
  }

  // To handle object dropdown change in batch/schedule filter screen
  handleObjectChange(event) {
    this.strObject = event.detail.value;
    this.getContentDocumentLinkFields();
  }

  // To validate the filter conditions which are given in batch/schedule screen
  async handleValidate() {
    try {
      this.bolSpinner = true;
      let strMessage = "";
      if (this.tStartTime === undefined) {
        strMessage = strMessage + Preferred_Time + ", ";
      }
      if (this.strName === undefined || this.strName === "") {
        strMessage = strMessage + JOB_NAME + ", ";
      }

      if (
        this.strFrequency === "Weekly" &&
        this.bolSunday == false &&
        this.bolMonday == false &&
        this.bolTuesday == false &&
        this.bolWednesday == false &&
        this.bolThursday == false &&
        this.bolFriday == false &&
        this.bolSatday == false
      ) {
        strMessage = strMessage + Weekdays + ", ";
      }
      if (strMessage === "" || this.bolRunBatch) {
        if (
          this.bolAllFiles &&
          !this.bolAttachmentsByObjectCheck &&
          !this.bolFileBatchCDL
        ) {

          let strQuery =
            this.strBatchType === "Migrate Attachments"
              ? "SELECT Id FROM Attachment"
              : "SELECT Id FROM ContentDocument";
          await validateQuery({ strQuery: strQuery, bolScheduleApex: this.bolScheduleApex })
            .then(result => {
              if (result == this.CUSTOM_LABELS.Success) {
                this.strWhere = "";
                this.bolSpinner = false;
                this.bolValidated = true;
              } else {
                this.showNotification(Error, result, "Error");
                this.strWhere = "";
                this.bolSpinner = false;
                this.bolValidated = false;
              }
            })
            .catch(error => {
              this.bolSpinner = false;
              this.showNotification(Error, error.message, "Error");
              this.bolValidated = false;
            });
        } else {
          const bolValid = [
            ...this.template.querySelectorAll(".reqValidation")
          ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
          }, true);
          if (bolValid) {
            if (
              this.bolFileBatch ||
              this.bolAttachmentsCheck ||
              this.bolFileBatchCDL ||
              this.bolAttachmentsByObjectCheck
            ) {
              if (this.bolManualBatchCondition) {
                let strQuery =
                  this.strBatchType === "Migrate Attachments" ||
                    this.strBatchType === "Migrate Attachments By Object"
                    ? "SELECT Id FROM Attachment WHERE " + this.strWhere
                    : this.strBatchType === "Migrate Files"
                      ? "SELECT Id FROM ContentDocument WHERE " + this.strWhere
                      : "SELECT Id FROM ContentdocumentLink WHERE ContentDocument.LatestPublishedVersion.Is_Migrated__c = false AND " +
                      this.strWhere;
                await validateQuery({ strQuery: strQuery, bolScheduleApex: this.bolScheduleApex })
                  .then(result => {
                    if (result == this.CUSTOM_LABELS.Success) {
                      this.bolSpinner = false;
                      this.bolValidated = true;
                    } else {
                      this.showNotification(Error, result, "Error");
                      this.bolSpinner = false;
                      this.bolValidated = false;
                    }
                  })
                  .catch(error => {
                    this.bolSpinner = false;
                    this.showNotification(Error, error.message, "Error");
                    this.bolValidated = false;
                  });
              } else {
                let mapOptions = new Map();
                let strConditionWithLogic = "";

                for (let i = 0; i < this.arrConditions.length; i++) {
                  if (
                    this.strConditionalLogic.includes(
                      this.arrConditions[i].key.toString()
                    )
                  ) {
                    mapOptions.set(
                      this.arrConditions[i].key,
                      this.arrConditions[i]
                    );
                  } else {
                    this.showNotification(
                      Error,
                      Add_conditional_logic_for_all_conditions,
                      "Error"
                    );
                    break;
                  }
                }
                for (let j = 0; j < this.strConditionalLogic.length; j++) {
                  if (mapOptions.has(parseInt(this.strConditionalLogic[j]))) {
                    let strfield = mapOptions.get(
                      parseInt(this.strConditionalLogic[j])
                    ).strField;
                    let stroperator = mapOptions.get(
                      parseInt(this.strConditionalLogic[j])
                    ).strOperator;
                    let strvalue = mapOptions.get(
                      parseInt(this.strConditionalLogic[j])
                    ).strValue;
                    console.log('strvalue::', strvalue);
                    let selectedOption = this.arrFieldOptions.find(
                      option => option.label === strfield
                    );
                    // ---- FIX: only quote the value ONCE. Previously this block
                    // wrapped ID/REFERENCE/STRING/PICKLIST/TEXTAREA values in quotes,
                    // and then the block below wrapped it in quotes AGAIN, producing
                    // doubled/escaped quotes like '\'003dL00001sAzc7QAC\''.
                    // Now this block only builds the IN/NOT IN list (which needs its
                    // own parenthesized, per-value quoting) or clears the value when
                    // empty/null. Plain equality/comparison values are left RAW here
                    // and quoted exactly once in the block below.
                    if (selectedOption) {
                      if (
                        selectedOption.type == "ID" ||
                        selectedOption.type == "REFERENCE" ||
                        selectedOption.type == "STRING" ||
                        selectedOption.type == "PICKLIST" ||
                        selectedOption.type == "TEXTAREA"
                      ) {
                        if (stroperator == 'IN' || stroperator == 'NOT IN') {
                          strvalue = "(" + strvalue.split(',').map(val => `'${val.trim()}'`).join(',') + ")";
                        } else if (strvalue.trim().length == 0 || strvalue.toLowerCase() == 'null') {
                          strvalue = '';
                        }
                        // else: leave strvalue RAW — it gets quoted once below
                      }
                    }
                    console.log('strvalue1::', strvalue);
                    if (strvalue == '') {
                      strConditionWithLogic += strfield + ' ' + stroperator + ' null';
                    } else if (stroperator == 'IN' || stroperator == 'NOT IN') {
                      // strvalue is already a parenthesized, quoted list - don't re-wrap it
                      strConditionWithLogic += strfield + ' ' + stroperator + ' ' + strvalue;
                    } else {
                      strConditionWithLogic += strfield + ' ' + stroperator + ' \'' + strvalue.replace(/'/g, '\\$&') + '\'';
                    }
                  } else {
                    strConditionWithLogic += this.strConditionalLogic[j];
                  }
                }
                if (strConditionWithLogic != "") {
                  let strQuery =
                    this.strBatchType === "Migrate Attachments" ||
                      this.strBatchType === "Migrate Attachments By Object"
                      ? this.strObject != null &&
                        this.strObject != "" &&
                        this.strObject != " "
                        ? "SELECT Id FROM Attachment WHERE ParentId IN (SELECT Id FROM " +
                        this.strObject +
                        " WHERE " +
                        strConditionWithLogic +
                        ")"
                        : "SELECT Id FROM Attachment WHERE " +
                        strConditionWithLogic
                      : this.strBatchType === "Migrate Files" && (this.strObject == null ||
                        this.strObject == "")
                        ? "SELECT Id FROM ContentDocument WHERE LatestPublishedVersion.Is_Migrated__c = false AND " +
                        strConditionWithLogic
                        : "SELECT Id FROM ContentdocumentLink WHERE ContentDocument.LatestPublishedVersion.Is_Migrated__c = false AND LinkedEntityId IN (SELECT Id FROM " +
                        this.strObject +
                        " WHERE " +
                        strConditionWithLogic +
                        ")";
                        console.log('strQuery::', strQuery);
                  await validateQuery({ strQuery: strQuery, bolScheduleApex: this.bolScheduleApex })
                    .then(result => {
                      console.log('result::', result);
                      if (result == this.CUSTOM_LABELS.Success) {
                        this.strWhere = strConditionWithLogic;

                        if (this.bolFileBatchCDL) {
                          this.strWhere =
                            "LinkedEntityId IN (SELECT Id FROM " +
                            this.strObject +
                            " WHERE " +
                            strConditionWithLogic +
                            ")";
                        } else if (
                          this.bolAttachmentsByObjectCheck
                        ) {
                          this.strWhere =
                            "ParentId IN (SELECT Id FROM " +
                            this.strObject +
                            " WHERE " +
                            strConditionWithLogic +
                            ")";
                        }
                        this.bolSpinner = false;
                        this.bolValidated = true;
                      } else {
                        this.showNotification(Error, result, "Error");
                        this.bolSpinner = false;
                        this.bolValidated = false;
                      }
                    })
                    .catch(error => {
                      this.bolSpinner = false;
                      this.showNotification(Error, error.message, "Error");
                      this.bolValidated = false;
                    });
                }
              }
            }
          } else {
            this.bolSpinner = false;
            this.bolValidated = false;
          }
        }
      } else {
        strMessage = strMessage.slice(0, -2);
        strMessage =
          Please_populate + " " + strMessage + " " + to_proceed_further;
        this.showNotification(Required_fields_are_missing, strMessage, "error");
        this.bolSpinner = false;
        this.bolValidated = false;
      }
    } catch (error) {
      console.log(error.message);
    }
  }
  // To validate the given email address
  validateEmail(email) {
    var regex = /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/;
    return regex.test(email);
  }

  // To handle field/operator/condition/value input field changes
  handleConditionChange(event) {
    let strInput = event.currentTarget.dataset.name;
    for (let i = 0; i < this.arrConditions.length; i++) {
      if (this.arrConditions[i].key == event.currentTarget.dataset.id) {
        if (strInput == "field") {
          this.arrConditions[i].strField = event.detail.value;
        } else if (strInput == "operator") {
          this.arrConditions[i].strOperator = event.detail.value;
          if(this.arrConditions[i].strOperator == '=' || this.arrConditions[i].strOperator == '!=') {
            if(this.arrConditions[i].strField == 'Id' && this.arrConditions[i].strOperator == '=') {
              this.arrConditions[i].isRequired = true;
            } else {
              this.arrConditions[i].isRequired = false;
            }
          }
        } else if (strInput == "value") {
          this.arrConditions[i].strValue = event.detail.value;
        }
        break;
      }
    }
    if (strInput == "conditionalLogic") {
      this.strConditionalLogic = event.detail.value;
    } else if (strInput == "manualCondition") {
      this.bolManualBatchCondition = true;
    } else if (strInput == "pickCondition") {
      this.bolManualBatchCondition = false;
    } else if (strInput == "manualWhereCondition") {
      this.strWhere = event.detail.value;
    } else if (strInput == "batchOption") {
      let strValue = event.detail.value;
      this.strBatchOption = strValue;
      if (strValue == "All") {
        this.bolAllFiles = true;
      } else {
        this.bolAllFiles = false;
      }
      this.strWhere = "";
    }
  }

  // To handle frequency input change
  handleChangeFrequency(event) {
    let strInput = event.currentTarget.dataset.name;
    this.strFrequency = strInput;
    if (strInput === "Weekly") {
      this.bolShowWeekly = true;
      this.bolShowMonthly = false;
      this.bolShowOnce = false;
    } else if (strInput === "Monthly") {
      this.bolShowWeekly = false;
      this.bolShowMonthly = true;
      this.bolShowOnce = false;
    } else {
      this.bolShowWeekly = false;
      this.bolShowMonthly = false;
      this.bolShowOnce = true;
    }
  }

  // To handle frequency input change
  handleChangeWeekly(event) {
    // this.strWeekly = event.detail.value;
    try {
      let strcurrentTarget = event.currentTarget.querySelector("input[type='checkbox']").dataset.name;

      switch (strcurrentTarget) {
        case "Sunday":
          this.bolSunday = this.bolSunday == false ? true : false;
          break;
        case "Monday":
          this.bolMonday = this.bolMonday == false ? true : false;
          break;
        case "Tuesday":
          this.bolTuesday = this.bolTuesday == false ? true : false;
          break;
        case "Wednesday":
          this.bolWednesday = this.bolWednesday == false ? true : false;
          break;
        case "Thursday":
          this.bolThursday = this.bolThursday == false ? true : false;
          break;
        case "Friday":
          this.bolFriday = this.bolFriday == false ? true : false;
          break;
        case "Saturday":
          this.bolSatday = this.bolSatday == false ? true : false;
          break;
        default:
      }
    } catch (error) {
      console.log('Error--- ', error.message);
    }

  }

  // To handle day input change
  handleDayChange(event) {
    this.strDay = event.detail.value;
  }

  // To handle week input change
  handleWeekChange(event) {
    this.strWeek = event.detail.value;
  }

  // To handle weekday input change
  handleWeekDayChange(event) {
    this.strWeekDay = event.detail.value;
  }

  // To handle day selection input change
  handleDaySelectionChange(event) {
    this.bolDayOfMonth = event.target.checked;
    this.bolWeekOfMonth = false;
  }

  // To handle month selection input change
  handleMonthSelectionChange(event) {
    this.bolWeekOfMonth = event.target.checked;
    this.bolDayOfMonth = false;
  }

  // To handle name input change
  handleName(event) {
    this.strName = event.detail.value;
  }

  // To handle batch selection input change
  handleBatchSelection(event) {
    this.bolShowJobDescription = true;
    this.strBatchType = event.target.name;
    this.strConditionalLogic = "1";
    this.bolDeleteUploadedRecords = false;
    this.bolIncludeUserRecords = false;
    this.strBatchOption = "Specific";
    this.bolAllFiles = false;
    this.bolBatchOption = true;
    if (this.strBatchType === "Migrate Files") {
      this.bolAttachmentsCheck = false;
      this.bolAttachmentsByObjectCheck = false;
      this.bolFileBatch = true;
      this.bolFileBatchCDL = false;
      this.arrConditions = [];
      this.handleAddRow();
      this.arrFieldOptions = [...this.arrContentDocFields];
      this.strJobDescription = Executing_this_batch_will_upload_all_the_Salesforce_files_to_the_External_Storag;
      this.strDeleteOriginalFileLabel = Delete_Original_File_after_upload;
      this.strBatchConditionHelpText = Batch_Condition_help_text;
      this.bolValidated = false;
      this.bolEvnt = false;
    } else if (this.strBatchType === "Migrate Attachments") {
      this.bolAttachmentsCheck = true;
      this.bolAttachmentsByObjectCheck = false;
      this.bolFileBatch = false;
      this.arrConditions = [];
      this.handleAddRow();
      this.bolFileBatchCDL = false;
      this.arrFieldOptions = [...this.arrAttachmentFields];
      this.strJobDescription = this.CUSTOM_LABELS.Executing_this_batch_will_upload_all_the_Salesforce_attachments_to_the_External;
      this.strDeleteOriginalFileLabel = this.CUSTOM_LABELS.Delete_Original_Attachment_after_upload;
      this.strBatchConditionHelpText = this.CUSTOM_LABELS.Batch_Condition_Help_Text_Attachment;
      this.bolEvnt = false;
    }
    else {
      this.bolAttachmentsCheck = false;
      this.bolAttachmentsByObjectCheck = false;
      this.bolFileBatch = false;
      this.bolFileBatchCDL = false;
      this.strJobDescription = "";
    }
  }

  // To schedule the selected job
  async handleScheduler() {
    let bolValidSubmit = true;
    let inputDateTime = "";
    let dtNow = new Date();
    let formattedDate = new Date(dtNow.getFullYear(), dtNow.getMonth(), dtNow.getDate(), dtNow.getHours(), dtNow.getMinutes(), 0);
    this.bolSpinner = true;
    await this.handleValidate();
    setTimeout(() => {
      if (this.bolValidated) {
        let strMessage = "";
        if (this.tStartTime === undefined) {
          strMessage = strMessage + Preferred_Time + ", ";
        }
        if (this.strName === undefined || this.strName === "") {
          strMessage = strMessage + JOB_NAME + ", ";
        }
        if (
          this.strFrequency === "Weekly" &&
          this.bolSunday == false &&
          this.bolMonday == false &&
          this.bolTuesday == false &&
          this.bolWednesday == false &&
          this.bolThursday == false &&
          this.bolFriday == false &&
          this.bolSatday == false
        ) {
          strMessage = strMessage + Weekdays + ", ";
        }
        if (strMessage === "") {
          let strSchedule = "";
          let hour = this.tStartTime.toString().substring(0, 2);
          let min = this.tStartTime.toString().substring(3, 5);
          if (this.strFrequency === "Monthly") {
            if (this.bolDayOfMonth) {
              strSchedule =
                "00 " + min + " " + hour + " " + this.strDay + " * ? *";
            } else {
              strSchedule =
                "00 " +
                min +
                " " +
                hour +
                " ? * " +
                this.strWeekDay +
                (this.strWeek === "L" ? "" : "#") +
                this.strWeek;
            }
            bolValidSubmit = false;
          } else if (this.strFrequency === "Weekly") {
            let strWeek = "";

            strWeek =
              (this.bolSunday ? "SUN," : "") +
              (this.bolMonday ? "MON," : "") +
              (this.bolTuesday ? "TUE," : "") +
              (this.bolWednesday ? "WED," : "") +
              (this.bolThursday ? "THU," : "") +
              (this.bolFriday ? "FRI," : "") +
              (this.bolSatday ? "SAT," : "");
            for (let i = 0; i < this.strWeekly.length; i++) {
              strWeek = strWeek + this.strWeekly[i] + ",";
            }
            strWeek = strWeek.slice(0, -1);
            strSchedule = "00 " + min + " " + hour + " ? * " + strWeek;
            bolValidSubmit = false;
          } else if (this.strFrequency === "Once") {
            let day = new Date(this.tStartDate).getDate();
            let month = new Date(this.tStartDate).getMonth() + 1;
            let year = new Date(this.tStartDate).getFullYear();
            strSchedule =
              "00 " + min + " " + hour + " " + day + " " + month + " ? " + year;
            inputDateTime = new Date(year, month - 1, day, hour, min, 0);
            bolValidSubmit = inputDateTime > formattedDate ? false : true;
          }

          if (!bolValidSubmit) {
            if (strSchedule !== "") {
              try {
                this.objScheduleJobWrapper.strName = this.strName;
                this.objScheduleJobWrapper.strCRON = strSchedule;
                this.objScheduleJobWrapper.strBatchType = this.strBatchType;
                this.objScheduleJobWrapper.strWhere = this.strWhere;
                this.objScheduleJobWrapper.bolIncludeUserRecords = this.bolIncludeUserRecords;
                this.objScheduleJobWrapper.bolDeleteUploadedRecords = this.bolDeleteUploadedRecords;
                this.objScheduleJobWrapper.strLastNdays = this.strLastNdays;

                scheduleJob({ strScheduleJobWrapper: JSON.stringify(this.objScheduleJobWrapper) })
                  .then(result => {
                    let idBatch = result;
                    if (idBatch !== "" && idBatch != null && !result.strMessage.includes('already scheduled for execution.')) {
                      this.bolDisableExecute = true;
                      this.stateManageJob.bolDisablePrevious = true;
                      this.showNotification(Success, result.strMessage, "Success");
                      this.bolSpinner = false;
                      this.hideBatchModalBox();
                      this.getScheduledApexJobs();
                      this.bolEvnt = false;
                    } else {
                      this.showNotification(Error, result.strMessage, "Error");
                      this.bolSpinner = false;
                    }
                  })
                  .catch(error => {
                    this.showNotification(Error, error.message, "error");
                    this.bolSpinner = false;
                  });
              } catch (error) {
                console.log('error-- ', error.message);

              }

            } else {
              this.showNotification(Error, Something_went_wrong, "error");
              this.bolSpinner = false;
            }
          } else {
            this.showNotification(Error, this.CUSTOM_LABELS.Preferred_Schedule_Date_Error_Message, "error");
            this.bolSpinner = false;
          }

        } else {
          strMessage = strMessage.slice(0, -2);
          strMessage =
            Please_populate + " " + strMessage + " " + to_proceed_further;
          this.showNotification(
            Required_fields_are_missing,
            strMessage,
            "error"
          );
          this.bolSpinner = false;
        }
      }
    }, 1000);
  }

  // To handle date input change
  handleDateChange(event) {
    this.tStartDate = event.detail.value;
  }
  // To handle time input change
  handleTimeChange(event) {
    this.tStartTime = event.detail.value;
  }

  checkEditionPermissions() {
    checkEditionPermission()
      .then(result => {
        this.bolIsScheduleJobAllowed = result;
      })
      .catch(error => {
        console.error(error);
        this.bolIsScheduleJobAllowed = false;
      });
  }
  get disableScheduleButton() {
    return !this.bolIsScheduleJobAllowed;
  }
  showScheduleHelpText() {
    if (this.disableScheduleButton) {
      this.bolShowScheduleMessage = true;
    }
  }

  hideScheduleHelpText() {
    this.bolShowScheduleMessage = false;
  }

  // To handle Schedule Apex reload
  handleScheduleApex() {
    this.bolScheduleApex = true;
    this.bolShowBatchConfiguration = true;
    this.bolDisableExecute = false;
    this.strBatchType = "Migrate Files";
    this.bolFileBatch = true;
    this.bolBatchOption = true;
    this.bolShowJobDescription = true;
    this.strJobDescription = Executing_this_batch_will_upload_all_the_Salesforce_files_to_the_External_Storag;
    this.bolBatchJobId = false;
    this.stateManageJob.bolDisablePrevious = true;
    this.stateManageJob.bolDisableNext = false;
    this.strCurrentStep = "1";
    this.stateManageJob.bolFirstStep = true;
    this.stateManageJob.bolSecondStep = false;
    this.stateManageJob.bolThirdStep = false;
    this.bolRunBatch = false;
  }

  // The below methos is to delete the multiple schedule jobs.
  handleRowDelAction(event) {

    this.strJobName = event.currentTarget.dataset.jobname;
    this.bolDelete = true;

  }

  // To execute the selected batch
  async handleExcuteBatch() {
    this.bolSpinner = true;
    await this.handleValidate();
    if (this.bolValidated) {
      try {
        this.objExcuteBatchJobWrapper.strBatchType = this.strBatchType;
        this.objExcuteBatchJobWrapper.strWhere = this.strWhere;
        this.objExcuteBatchJobWrapper.bolIncludeUserRecords = this.bolIncludeUserRecords;
        this.objExcuteBatchJobWrapper.bolDeleteUploadedRecords = this.bolDeleteUploadedRecords;
        this.objExcuteBatchJobWrapper.strLastNdays = this.strLastNdays;

        excuteBatchJob({ strExcuteBatchJobWrapper: JSON.stringify(this.objExcuteBatchJobWrapper) })
          .then(result => {
            if (result.strVariant === this.CUSTOM_LABELS.Success) {
              this.bolDisableExecute = true;
              this.stateManageJob.bolDisablePrevious = true;
              this.strBatchJobId = result.strJobId;
              this.bolBatchJobId = true;
              LightningToast.show(
                {
                  label: Success,
                  message: result.strMessage + '. {AsyncApexJobs} to navigate apex job page.',
                  messageLinks: {
                    AsyncApexJobs: {
                       url: '/lightning/setup/AsyncApexJobs/home/',
                      label: 'Click here'
                    }
                  },
                  mode: "sticky",
                  variant: "Success",
                },
                this,
              );
              this.handleBackToHome();
              this.bolEvnt = false;
            } else {
              if (result.strVariant === this.CUSTOM_LABELS.Success) {
                this.hideBatchModalBox();
                this.handleBackToHome();
                this.showNotification(
                  Success,
                  this.CUSTOM_LABELS.success_Message_job_initiated,
                  "Success"
                );
              } else {
                this.showNotification(Error, result.strMessage, "Error");
              }
            }
            this.bolSpinner = false;
          })
          .catch(error => {
            this.bolSpinner = false;
            this.showNotification(Error, error.message, "Error");
          });
      } catch (error) {
        console.log('Error-- ', error.message);

      }

    }
  }

  // To hide abort warning modal box
  hideAbortWarning() {
    this.bolShowAbortWarning = false;
    this.bolRunBatch = true;
  }

  // To abort the batch job
  handleAbortJob() {
    if (Number(this.intExecutedPercentage) == 100) {
      this.showNotification(Info, Cannot_abort_a_job_that_is_already_completed, 'info');
    } else {
      this.bolSpinner = true;
      let arrJobId = [this.strBatchJobId];
      abortBatchJob({ lstJobId: arrJobId })
        .then((result) => {
          if (result.strVariant === this.CUSTOM_LABELS.Success) {
            this.showNotification(Success, result.strMessage, "Success");
            this.hideAbortWarning();
            refreshApex(this.wiredallRunningBatchData);
            this.getBatchStatus();
            this.bolDisableAbort = true;
            this.bolSpinner = false;
          } else {
            this.showNotification(Error, result.strMessage, "Error");
            this.bolSpinner = false;
          }
        })
        .catch((error) => {
          this.bolSpinner = false;
          this.showNotification(Error, error.message, "Error");
        });
    }

  }

  // To get the batch status
  getBatchStatus() {
    getJobDetails({ idJob: this.strBatchJobId })
      .then(res => {
        if (res[0]) {
          this.bolDisableAbort = false;
          this.intExecutedPercentage =
            res[0].TotalJobItems === 0
              ? 0
              : (res[0].JobItemsProcessed / res[0].TotalJobItems * 100).toFixed(
                2
              );
          let executedNumber = Number(this.intExecutedPercentage);
          this.strBatchStatus = res[0].Status;
          if (
            this.strBatchStatus != Completed &&
            this.strBatchStatus != Failed &&
            this.strBatchStatus != Aborted &&
            (this.bolRunBatch || this.bolShowAbortWarning)
          ) {
            setTimeout(() => {
              this.getBatchStatus();
            }, 2000);
          } else {
            this.bolDisableAbort = true;
          }
        }
      })
      .catch(err => {
        this.objLogErrorWrapper = {};
        this.objLogErrorWrapper.relatedTo = "JobConfigurationsController.getJobDetails";
        this.objLogErrorWrapper.summary = "";
        this.objLogErrorWrapper.message = err;
        this.objLogErrorWrapper.batchJobId = "";
        this.objLogErrorWrapper.recordIds = "";
        this.objLogErrorWrapper.statusCode = "";

        logError({ strLogErrorWrapper: JSON.stringify(this.objLogErrorWrapper) });
        this.showNotification(Error, err.message, "Error");
      });
  }

  // To handle Batch input modal logics
  handleRunBatch() {
    this.bolShowBatchConfiguration = true;
    this.bolDisableExecute = false;
    this.bolRunBatch = true;
    this.strBatchType = "Migrate Files";
    this.bolFileBatch = true;
    this.bolBatchOption = true;
    this.bolShowJobDescription = true;
    this.strJobDescription = Executing_this_batch_will_upload_all_the_Salesforce_files_to_the_External_Storag;
    this.bolBatchJobId = false;
    this.strCurrentStep = "1";
    this.stateManageJob.bolDisablePrevious = true;
    this.stateManageJob.bolDisableNext = false;
    this.stateManageJob.bolFirstStep = true;
    this.stateManageJob.bolSecondStep = false;
    this.stateManageJob.bolThirdStep = false;
    //this.strEmails = "";
  }

  // To hide batch input modal box logics

  ScheduleJobcloseModal() {
    this.hideBatchModalBox();
    this.bolScheduleJobModelBox = false;
    this.strName = "";
    this.bolDeleteUploadedRecords = false;
    this.bolIncludeUserRecords = false;
    this.strLastNdays = "";
    this.strFrequency = "Weekly";
    this.strWeekly = "";
    this.bolDayOfMonth = true;
    this.strDay = "1";
    this.strWeek = "1";
    this.strWeekDay = "";
    this.tStartTime = "";
    this.bolShowJobDescription = false;
  }

  hideBatchModalBox() {

    if (
      this.strBatchStatus != Completed &&
      this.strBatchStatus != Failed &&
      this.strBatchStatus != Aborted &&
      this.bolShowBatchConfiguration == false &&
      this.strBatchJobId != "" &&
      this.strBatchJobId != undefined
    ) {
      this.showNotification(Info, this.CUSTOM_LABELS.Batch_job_will_run_in_the_background_Please_use_the_batch_status_to_monitor_the, "Info");
    }
    this.bolRunBatch = false;
    this.bolDeleteUploadedRecords = false;
    this.bolIncludeUserRecords = false;
    this.bolAttachmentsCheck = false;
    this.bolAttachmentsByObjectCheck = false;
    this.bolFileBatchCDL = false;
    this.bolBatchOption = false;
    this.bolShowJobDescription = false;
    this.strLastNdays = "";
    this.strConditionalLogic = "1";
    this.arrConditions = [];
    this.strWhere = "";
    this.strBatchOption = "Specific";
    this.bolAllFiles = false;
    this.handleAddRow();
    this.bolShowBatchConfiguration = false;
    this.strName = "";
    this.strFrequency = "Once";
    this.bolShowOnce = true;
    this.bolShowWeekly = false;
    this.bolShowMonthly = false;
    this.bolSunday = false;
    this.bolMonday = false;
    this.bolTuesday = false;
    this.bolWednesday = false;
    this.bolThursday = false;
    this.bolFriday = false;
    this.bolSatday = false;
    this.bolDayOfMonth = true;
    this.strDay = "1";
    this.strWeek = "1";
    this.strWeekDay = "";
    this.tStartTime = "";
    this.bolShowJobDescription = false;
    this.bolEvnt = false;
    this.strObject = "";
    this.tStartDate = "";
    this.strDeleteOriginalFileLabel = Delete_Original_File_after_upload;
    this.strBatchConditionHelpText = Batch_Condition_help_text;
    this.arrFieldOptions = [...this.arrContentDocFields];
    this.strBatchJobId = "";
  }

  // To handle job condition input change
  handleExcuteJobCondition(event) {
    this.strWhere = event.detail.value;
  }

  // To handle user record param for batch input change
  handleUserIncludeOptionChange(event) {
    this.bolIncludeUserRecords = event.target.checked;
  }

  // To handle delete uploaded param for batch input change
  handleDeleteChange(event) {
    this.bolDeleteUploadedRecords = event.target.checked;
  }

  // Toast notification common method
  showNotification(strTitle, strMessage, strType) {
    let strMode = strType === "error" ? "sticky" : "dismissable";
    const objToastEvent = new ShowToastEvent({
      title: strTitle,
      message: strMessage,
      variant: strType,
      mode: strMode
    });
    this.dispatchEvent(objToastEvent);
  }

  handleObjChangeToggle(event) {
    this.bolEvnt = event.target.checked;

    if ((this.bolFileBatch == true || this.bolFileBatchCDL == true) && (this.bolAttachmentsCheck == false && this.bolAttachmentsByObjectCheck == false)) {
      this.bolAttachmentsCheck = false;
      this.bolAttachmentsByObjectCheck = false;
      this.bolFileBatchCDL = this.bolEvnt;
      this.arrConditions = [];
      this.handleAddRow();
      this.strJobDescription = Executing_this_batch_will_upload_on_the_content_document_link_provided;
      this.arrFieldOptions = this.bolEvnt ? [] : [...this.arrContentDocFields];
      this.strBatchConditionHelpText = Batch_Condition_help_text;
      if (this.bolFileBatchCDL) {
        this.strBatchType = "Migrate Files By Object";
        this.strBatchConditionHelpText = Batch_Condition_help_text_CDL;
      } else {
        this.strBatchType = "Migrate Files";
      }
    } else if (this.bolAttachmentsCheck == true || this.bolAttachmentsByObjectCheck == true) {
      this.bolAttachmentsCheck = !this.bolEvnt;
      this.bolAttachmentsByObjectCheck = this.bolEvnt;
      this.bolFileBatchCDL = false;
      this.arrConditions = [];
      this.handleAddRow();
      this.arrFieldOptions = this.bolEvnt ? [] : [...this.arrAttachmentFields];
      this.strJobDescription = this.CUSTOM_LABELS.sExecuting_this_batch_will_upload_all_the_Salesforce_attachments_to_the_External + " based on the object selection";
      this.strDeleteOriginalFileLabel = this.CUSTOM_LABELS.Delete_Original_Attachment_after_upload;
      this.strBatchConditionHelpText = this.bolAttachmentsCheck == true ? this.CUSTOM_LABELS.Batch_Condition_Help_Text_Attachment : this.CUSTOM_LABELS.Batch_Condition_Help_Text_AttachmentParent;
    }

    if (this.bolEvnt == false) {
      this.strObject = null;
    }

  }

  handleConfirmDelete() {
    //Bug fix - Handle the delete
    this.bolDelete = false;
    this.bolSpinner = true;
    deleteScheduledJobs({
      strJobName: this.strJobName
    })
      .then(result => {
        this.showNotification(Success, Success_message_job_Deleted, "Success");
        this.getScheduledApexJobs();
        this.bolSpinner = false;
      })
      .catch(error => {
        this.bolSpinner = false;
        this.showNotification(Error, error.message, "Error");
      });
  }

  hideDeleteModal() {
    this.bolDelete = false;
  }

  async handleAlertClick() {
    await LightningAlert.open({
      message: Alert_Message,
      theme: "warning", // a red theme intended for error states
      label: Alert // this is the header text
    });
    //Alert has been closed
  }

}