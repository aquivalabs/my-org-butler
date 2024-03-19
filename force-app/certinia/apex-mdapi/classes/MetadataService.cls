/**
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

public class MetadataService {
    public static String SOAP_M_URI = 'http://soap.sforce.com/2006/04/metadata';

    public class SessionHeader_element {
        public String sessionId;
        private String[] sessionId_type_info = new String[]{'sessionId',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'sessionId'};
    }

    public class AsyncResult {
        public Boolean done;
        public String id;
        public String message;
        public String state;
        public String statusCode;
        private String[] done_type_info = new String[]{'done',SOAP_M_URI,null,'1','1','false'};
        private String[] id_type_info = new String[]{'id',SOAP_M_URI,null,'1','1','false'};
        private String[] message_type_info = new String[]{'message',SOAP_M_URI,null,'0','1','false'};
        private String[] state_type_info = new String[]{'state',SOAP_M_URI,null,'1','1','false'};
        private String[] statusCode_type_info = new String[]{'statusCode',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'done','id','message','state','statusCode'};
    }

    public class CodeCoverageWarning {
        public String id;
        public String message;
        public String name;
        public String namespace;
        private String[] id_type_info = new String[]{'id',SOAP_M_URI,null,'1','1','false'};
        private String[] message_type_info = new String[]{'message',SOAP_M_URI,null,'1','1','false'};
        private String[] name_type_info = new String[]{'name',SOAP_M_URI,null,'1','1','true'};
        private String[] namespace_type_info = new String[]{'namespace',SOAP_M_URI,null,'1','1','true'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'id','message','name','namespace'};
    }

    public class RunTestSuccess {
        public String id;
        public String methodName;
        public String name;
        public String namespace;
        public Boolean seeAllData;
        public Double time_x;
        private String[] id_type_info = new String[]{'id',SOAP_M_URI,null,'1','1','false'};
        private String[] methodName_type_info = new String[]{'methodName',SOAP_M_URI,null,'1','1','false'};
        private String[] name_type_info = new String[]{'name',SOAP_M_URI,null,'1','1','false'};
        private String[] namespace_type_info = new String[]{'namespace',SOAP_M_URI,null,'1','1','true'};
        private String[] seeAllData_type_info = new String[]{'seeAllData',SOAP_M_URI,null,'0','1','false'};
        private String[] time_x_type_info = new String[]{'time',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'id','methodName','name','namespace','seeAllData','time_x'};
    }

    public class checkDeployStatus_element {
        public String asyncProcessId;
        public Boolean includeDetails;
        private String[] asyncProcessId_type_info = new String[]{'asyncProcessId',SOAP_M_URI,null,'1','1','false'};
        private String[] includeDetails_type_info = new String[]{'includeDetails',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'asyncProcessId','includeDetails'};
    }
    public class RetrieveMessage {
        public String fileName;
        public String problem;
        private String[] fileName_type_info = new String[]{'fileName',SOAP_M_URI,null,'1','1','false'};
        private String[] problem_type_info = new String[]{'problem',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'fileName','problem'};
    }
    public class CodeLocation {
        public Integer column;
        public Integer line;
        public Integer numExecutions;
        public Double time_x;
        private String[] column_type_info = new String[]{'column',SOAP_M_URI,null,'1','1','false'};
        private String[] line_type_info = new String[]{'line',SOAP_M_URI,null,'1','1','false'};
        private String[] numExecutions_type_info = new String[]{'numExecutions',SOAP_M_URI,null,'1','1','false'};
        private String[] time_x_type_info = new String[]{'time',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'column','line','numExecutions','time_x'};
    }
    public class DeployResult {
        public String canceledBy;
        public String canceledByName;
        public Boolean checkOnly;
        public DateTime completedDate;
        public String createdBy;
        public String createdByName;
        public DateTime createdDate;
        public MetadataService.DeployDetails details;
        public Boolean done;
        public String errorMessage;
        public String errorStatusCode;
        public String id;
        public Boolean ignoreWarnings;
        public DateTime lastModifiedDate;
        public Integer numberComponentErrors;
        public Integer numberComponentsDeployed;
        public Integer numberComponentsTotal;
        public Integer numberTestErrors;
        public Integer numberTestsCompleted;
        public Integer numberTestsTotal;
        public Boolean rollbackOnError;
        public Boolean runTestsEnabled;
        public DateTime startDate;
        public String stateDetail;
        public String status;
        public Boolean success;
        private String[] canceledBy_type_info = new String[]{'canceledBy',SOAP_M_URI,null,'0','1','false'};
        private String[] canceledByName_type_info = new String[]{'canceledByName',SOAP_M_URI,null,'0','1','false'};
        private String[] checkOnly_type_info = new String[]{'checkOnly',SOAP_M_URI,null,'1','1','false'};
        private String[] completedDate_type_info = new String[]{'completedDate',SOAP_M_URI,null,'0','1','false'};
        private String[] createdBy_type_info = new String[]{'createdBy',SOAP_M_URI,null,'1','1','false'};
        private String[] createdByName_type_info = new String[]{'createdByName',SOAP_M_URI,null,'1','1','false'};
        private String[] createdDate_type_info = new String[]{'createdDate',SOAP_M_URI,null,'1','1','false'};
        private String[] details_type_info = new String[]{'details',SOAP_M_URI,null,'1','1','false'};
        private String[] done_type_info = new String[]{'done',SOAP_M_URI,null,'1','1','false'};
        private String[] errorMessage_type_info = new String[]{'errorMessage',SOAP_M_URI,null,'0','1','false'};
        private String[] errorStatusCode_type_info = new String[]{'errorStatusCode',SOAP_M_URI,null,'0','1','false'};
        private String[] id_type_info = new String[]{'id',SOAP_M_URI,null,'1','1','false'};
        private String[] ignoreWarnings_type_info = new String[]{'ignoreWarnings',SOAP_M_URI,null,'1','1','false'};
        private String[] lastModifiedDate_type_info = new String[]{'lastModifiedDate',SOAP_M_URI,null,'0','1','false'};
        private String[] numberComponentErrors_type_info = new String[]{'numberComponentErrors',SOAP_M_URI,null,'1','1','false'};
        private String[] numberComponentsDeployed_type_info = new String[]{'numberComponentsDeployed',SOAP_M_URI,null,'1','1','false'};
        private String[] numberComponentsTotal_type_info = new String[]{'numberComponentsTotal',SOAP_M_URI,null,'1','1','false'};
        private String[] numberTestErrors_type_info = new String[]{'numberTestErrors',SOAP_M_URI,null,'1','1','false'};
        private String[] numberTestsCompleted_type_info = new String[]{'numberTestsCompleted',SOAP_M_URI,null,'1','1','false'};
        private String[] numberTestsTotal_type_info = new String[]{'numberTestsTotal',SOAP_M_URI,null,'1','1','false'};
        private String[] rollbackOnError_type_info = new String[]{'rollbackOnError',SOAP_M_URI,null,'1','1','false'};
        private String[] runTestsEnabled_type_info = new String[]{'runTestsEnabled',SOAP_M_URI,null,'1','1','false'};
        private String[] startDate_type_info = new String[]{'startDate',SOAP_M_URI,null,'0','1','false'};
        private String[] stateDetail_type_info = new String[]{'stateDetail',SOAP_M_URI,null,'0','1','false'};
        private String[] status_type_info = new String[]{'status',SOAP_M_URI,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'canceledBy','canceledByName','checkOnly','completedDate','createdBy','createdByName','createdDate','details','done','errorMessage','errorStatusCode','id','ignoreWarnings','lastModifiedDate','numberComponentErrors','numberComponentsDeployed','numberComponentsTotal','numberTestErrors','numberTestsCompleted','numberTestsTotal','rollbackOnError','runTestsEnabled','startDate','stateDetail','status','success'};
    }

    public class CodeCoverageResult {
        public MetadataService.CodeLocation[] dmlInfo;
        public String id;
        public MetadataService.CodeLocation[] locationsNotCovered;
        public MetadataService.CodeLocation[] methodInfo;
        public String name;
        public String namespace;
        public Integer numLocations;
        public Integer numLocationsNotCovered;
        public MetadataService.CodeLocation[] soqlInfo;
        public MetadataService.CodeLocation[] soslInfo;
        public String type_x;
        private String[] dmlInfo_type_info = new String[]{'dmlInfo',SOAP_M_URI,null,'0','-1','false'};
        private String[] id_type_info = new String[]{'id',SOAP_M_URI,null,'1','1','false'};
        private String[] locationsNotCovered_type_info = new String[]{'locationsNotCovered',SOAP_M_URI,null,'0','-1','false'};
        private String[] methodInfo_type_info = new String[]{'methodInfo',SOAP_M_URI,null,'0','-1','false'};
        private String[] name_type_info = new String[]{'name',SOAP_M_URI,null,'1','1','false'};
        private String[] namespace_type_info = new String[]{'namespace',SOAP_M_URI,null,'1','1','true'};
        private String[] numLocations_type_info = new String[]{'numLocations',SOAP_M_URI,null,'1','1','false'};
        private String[] numLocationsNotCovered_type_info = new String[]{'numLocationsNotCovered',SOAP_M_URI,null,'1','1','false'};
        private String[] soqlInfo_type_info = new String[]{'soqlInfo',SOAP_M_URI,null,'0','-1','false'};
        private String[] soslInfo_type_info = new String[]{'soslInfo',SOAP_M_URI,null,'0','-1','false'};
        private String[] type_x_type_info = new String[]{'type',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'dmlInfo','id','locationsNotCovered','methodInfo','name','namespace','numLocations','numLocationsNotCovered','soqlInfo','soslInfo','type_x'};
    }

    public class RunTestsResult {
        public String apexLogId;
        public MetadataService.CodeCoverageResult[] codeCoverage;
        public MetadataService.CodeCoverageWarning[] codeCoverageWarnings;
        public MetadataService.RunTestFailure[] failures;
        public Integer numFailures;
        public Integer numTestsRun;
        public MetadataService.RunTestSuccess[] successes;
        public Double totalTime;
        private String[] apexLogId_type_info = new String[]{'apexLogId',SOAP_M_URI,null,'0','1','false'};
        private String[] codeCoverage_type_info = new String[]{'codeCoverage',SOAP_M_URI,null,'0','-1','false'};
        private String[] codeCoverageWarnings_type_info = new String[]{'codeCoverageWarnings',SOAP_M_URI,null,'0','-1','false'};
        private String[] failures_type_info = new String[]{'failures',SOAP_M_URI,null,'0','-1','false'};
        private String[] numFailures_type_info = new String[]{'numFailures',SOAP_M_URI,null,'1','1','false'};
        private String[] numTestsRun_type_info = new String[]{'numTestsRun',SOAP_M_URI,null,'1','1','false'};
        private String[] successes_type_info = new String[]{'successes',SOAP_M_URI,null,'0','-1','false'};
        private String[] totalTime_type_info = new String[]{'totalTime',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'apexLogId','codeCoverage','codeCoverageWarnings','failures','numFailures','numTestsRun','successes','totalTime'};
    }

    public class RunTestFailure {
        public String id;
        public String message;
        public String methodName;
        public String name;
        public String namespace;
        public String packageName;
        public Boolean seeAllData;
        public String stackTrace;
        public Double time_x;
        public String type_x;
        private String[] id_type_info = new String[]{'id',SOAP_M_URI,null,'1','1','false'};
        private String[] message_type_info = new String[]{'message',SOAP_M_URI,null,'1','1','false'};
        private String[] methodName_type_info = new String[]{'methodName',SOAP_M_URI,null,'1','1','true'};
        private String[] name_type_info = new String[]{'name',SOAP_M_URI,null,'1','1','false'};
        private String[] namespace_type_info = new String[]{'namespace',SOAP_M_URI,null,'1','1','true'};
        private String[] packageName_type_info = new String[]{'packageName',SOAP_M_URI,null,'1','1','false'};
        private String[] seeAllData_type_info = new String[]{'seeAllData',SOAP_M_URI,null,'0','1','false'};
        private String[] stackTrace_type_info = new String[]{'stackTrace',SOAP_M_URI,null,'1','1','true'};
        private String[] time_x_type_info = new String[]{'time',SOAP_M_URI,null,'1','1','false'};
        private String[] type_x_type_info = new String[]{'type',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'id','message','methodName','name','namespace','packageName','seeAllData','stackTrace','time_x','type_x'};
    }
    public class DeployDetails {
        public MetadataService.DeployMessage[] componentFailures;
        public MetadataService.DeployMessage[] componentSuccesses;
        public MetadataService.RetrieveResult retrieveResult;
        public MetadataService.RunTestsResult runTestResult;
        private String[] componentFailures_type_info = new String[]{'componentFailures',SOAP_M_URI,null,'0','-1','false'};
        private String[] componentSuccesses_type_info = new String[]{'componentSuccesses',SOAP_M_URI,null,'0','-1','false'};
        private String[] retrieveResult_type_info = new String[]{'retrieveResult',SOAP_M_URI,null,'0','1','false'};
        private String[] runTestResult_type_info = new String[]{'runTestResult',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'componentFailures','componentSuccesses','retrieveResult','runTestResult'};
    }

    public class RetrieveResult {
        public Boolean done;
        public String errorMessage;
        public String errorStatusCode;
        public MetadataService.FileProperties[] fileProperties;
        public String id;
        public MetadataService.RetrieveMessage[] messages;
        public String status;
        public Boolean success;
        public String zipFile;
        private String[] done_type_info = new String[]{'done',SOAP_M_URI,null,'1','1','false'};
        private String[] errorMessage_type_info = new String[]{'errorMessage',SOAP_M_URI,null,'0','1','false'};
        private String[] errorStatusCode_type_info = new String[]{'errorStatusCode',SOAP_M_URI,null,'0','1','false'};
        private String[] fileProperties_type_info = new String[]{'fileProperties',SOAP_M_URI,null,'0','-1','false'};
        private String[] id_type_info = new String[]{'id',SOAP_M_URI,null,'1','1','false'};
        private String[] messages_type_info = new String[]{'messages',SOAP_M_URI,null,'0','-1','false'};
        private String[] status_type_info = new String[]{'status',SOAP_M_URI,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',SOAP_M_URI,null,'1','1','false'};
        private String[] zipFile_type_info = new String[]{'zipFile',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'done','errorMessage','errorStatusCode','fileProperties','id','messages','status','success','zipFile'};
    }
    public class FileProperties {
        public String createdById;
        public String createdByName;
        public DateTime createdDate;
        public String fileName;
        public String fullName;
        public String id;
        public String lastModifiedById;
        public String lastModifiedByName;
        public DateTime lastModifiedDate;
        public String manageableState;
        public String namespacePrefix;
        public String type_x;
        private String[] createdById_type_info = new String[]{'createdById',SOAP_M_URI,null,'1','1','false'};
        private String[] createdByName_type_info = new String[]{'createdByName',SOAP_M_URI,null,'1','1','false'};
        private String[] createdDate_type_info = new String[]{'createdDate',SOAP_M_URI,null,'1','1','false'};
        private String[] fileName_type_info = new String[]{'fileName',SOAP_M_URI,null,'1','1','false'};
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'1','1','false'};
        private String[] id_type_info = new String[]{'id',SOAP_M_URI,null,'1','1','false'};
        private String[] lastModifiedById_type_info = new String[]{'lastModifiedById',SOAP_M_URI,null,'1','1','false'};
        private String[] lastModifiedByName_type_info = new String[]{'lastModifiedByName',SOAP_M_URI,null,'1','1','false'};
        private String[] lastModifiedDate_type_info = new String[]{'lastModifiedDate',SOAP_M_URI,null,'1','1','false'};
        private String[] manageableState_type_info = new String[]{'manageableState',SOAP_M_URI,null,'0','1','false'};
        private String[] namespacePrefix_type_info = new String[]{'namespacePrefix',SOAP_M_URI,null,'0','1','false'};
        private String[] type_x_type_info = new String[]{'type',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'createdById','createdByName','createdDate','fileName','fullName','id','lastModifiedById','lastModifiedByName','lastModifiedDate','manageableState','namespacePrefix','type_x'};
    }
    public class DeployMessage {
        public Boolean changed;
        public Integer columnNumber;
        public String componentType;
        public Boolean created;
        public DateTime createdDate;
        public Boolean deleted;
        public String fileName;
        public String fullName;
        public String id;
        public Integer lineNumber;
        public String problem;
        public String problemType;
        public Boolean success;
        private String[] changed_type_info = new String[]{'changed',SOAP_M_URI,null,'1','1','false'};
        private String[] columnNumber_type_info = new String[]{'columnNumber',SOAP_M_URI,null,'0','1','false'};
        private String[] componentType_type_info = new String[]{'componentType',SOAP_M_URI,null,'0','1','false'};
        private String[] created_type_info = new String[]{'created',SOAP_M_URI,null,'1','1','false'};
        private String[] createdDate_type_info = new String[]{'createdDate',SOAP_M_URI,null,'1','1','false'};
        private String[] deleted_type_info = new String[]{'deleted',SOAP_M_URI,null,'1','1','false'};
        private String[] fileName_type_info = new String[]{'fileName',SOAP_M_URI,null,'1','1','false'};
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'1','1','false'};
        private String[] id_type_info = new String[]{'id',SOAP_M_URI,null,'0','1','false'};
        private String[] lineNumber_type_info = new String[]{'lineNumber',SOAP_M_URI,null,'0','1','false'};
        private String[] problem_type_info = new String[]{'problem',SOAP_M_URI,null,'0','1','false'};
        private String[] problemType_type_info = new String[]{'problemType',SOAP_M_URI,null,'0','1','false'};
        private String[] success_type_info = new String[]{'success',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'changed','columnNumber','componentType','created','createdDate','deleted','fileName','fullName','id','lineNumber','problem','problemType','success'};
    }

    public class deploy_element {
        public String ZipFile;
        public MetadataService.DeployOptions DeployOptions;
        private String[] ZipFile_type_info = new String[]{'ZipFile',SOAP_M_URI,null,'1','1','false'};
        private String[] DeployOptions_type_info = new String[]{'DeployOptions',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'ZipFile','DeployOptions'};
    }  

    public class DeployOptions {
        public Boolean allowMissingFiles;
        public Boolean autoUpdatePackage;
        public Boolean checkOnly;
        public Boolean ignoreWarnings;
        public Boolean performRetrieve;
        public Boolean purgeOnDelete;
        public Boolean rollbackOnError;
        public String[] runTests;
        public Boolean singlePackage;
        public String testLevel;
        private String[] allowMissingFiles_type_info = new String[]{'allowMissingFiles',SOAP_M_URI,null,'1','1','false'};
        private String[] autoUpdatePackage_type_info = new String[]{'autoUpdatePackage',SOAP_M_URI,null,'1','1','false'};
        private String[] checkOnly_type_info = new String[]{'checkOnly',SOAP_M_URI,null,'1','1','false'};
        private String[] ignoreWarnings_type_info = new String[]{'ignoreWarnings',SOAP_M_URI,null,'1','1','false'};
        private String[] performRetrieve_type_info = new String[]{'performRetrieve',SOAP_M_URI,null,'1','1','false'};
        private String[] purgeOnDelete_type_info = new String[]{'purgeOnDelete',SOAP_M_URI,null,'1','1','false'};
        private String[] rollbackOnError_type_info = new String[]{'rollbackOnError',SOAP_M_URI,null,'1','1','false'};
        private String[] runTests_type_info = new String[]{'runTests',SOAP_M_URI,null,'0','-1','false'};
        private String[] singlePackage_type_info = new String[]{'singlePackage',SOAP_M_URI,null,'1','1','false'};
        private String[] testLevel_type_info = new String[]{'testLevel',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'allowMissingFiles','autoUpdatePackage','checkOnly','ignoreWarnings','performRetrieve','purgeOnDelete','rollbackOnError','runTests','singlePackage','testLevel'};
    }  

    public class deployResponse_element {
        public MetadataService.AsyncResult result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    public class checkDeployStatusResponse_element {
        public MetadataService.DeployResult result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
  
    public class MetadataPort {
        public String endpoint_x = URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/42.0';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        public MetadataService.SessionHeader_element SessionHeader;
        private String SessionHeader_hns = 'SessionHeader=http://soap.sforce.com/2006/04/metadata';
        private String[] ns_map_type_info = new String[]{SOAP_M_URI, 'MetadataService'};
   
    public MetadataService.AsyncResult deploy(String ZipFile,MetadataService.DeployOptions DeployOptions) {
        MetadataService.deploy_element request_x = new MetadataService.deploy_element();
        request_x.ZipFile = ZipFile;
        request_x.DeployOptions = DeployOptions;
        MetadataService.deployResponse_element response_x;
        Map<String, MetadataService.deployResponse_element> response_map_x = new Map<String, MetadataService.deployResponse_element>();
        response_map_x.put('response_x', response_x);
        WebServiceCallout.invoke(
            this,
            request_x,
            response_map_x,
            new String[]{endpoint_x,
            '',
            SOAP_M_URI,
            'deploy',
            SOAP_M_URI,
            'deployResponse',
            'MetadataService.deployResponse_element'}
        );
        response_x = response_map_x.get('response_x');
        return response_x.result;
    }

    public MetadataService.DeployResult checkDeployStatus(String asyncProcessId,Boolean includeDetails) {
        MetadataService.checkDeployStatus_element request_x = new MetadataService.checkDeployStatus_element();
        request_x.asyncProcessId = asyncProcessId;
        request_x.includeDetails = includeDetails;
        MetadataService.checkDeployStatusResponse_element response_x;
        Map<String, MetadataService.checkDeployStatusResponse_element> response_map_x = new Map<String, MetadataService.checkDeployStatusResponse_element>();
        response_map_x.put('response_x', response_x);
        WebServiceCallout.invoke(
        this,
        request_x,
        response_map_x,
        new String[]{endpoint_x,
        '',
        SOAP_M_URI,
        'checkDeployStatus',
        SOAP_M_URI,
        'checkDeployStatusResponse',
        'MetadataService.checkDeployStatusResponse_element'}
        );
        response_x = response_map_x.get('response_x');
        return response_x.result;
    }
  }
}