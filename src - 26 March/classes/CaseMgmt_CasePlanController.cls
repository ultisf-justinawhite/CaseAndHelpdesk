global class CaseMgmt_CasePlanController {
    @auraEnabled
    public static CaseManager manageCase(Id recordId){
        
        CaseManager caseManagerRecord = new CaseManager();
        caseStepWrapper caseStepWrpobj;
        List<Plan_Step__c> planStepList = new List<Plan_Step__c>();
        Map<Plan_Step__c,Case_Step__c> planStepAndCaseStepMap = new Map<Plan_Step__c, Case_Step__c>();
        List<Case_Step__c> caseStepList = new List<Case_Step__c>();
        Boolean flag = false;
        List<Case> caseRecords = new List<Case>([Select Id, Status,Case_Plan__c  From Case where Id =: recordId]);
        if(!caseRecords.isEmpty()){
            caseManagerRecord.CaseStatus = caseRecords[0].Status;
        }
        for(Plan_Step__c planStepObject : [Select Id, Name, Flow__c, Start_When__c, Associate_Case_Status__c, Is_Required__c From Plan_Step__c Where Case_Plan__c =: caseRecords[0].Case_Plan__c AND Associate_Case_Status__c =: caseRecords[0].Status ORDER BY CreatedDate ASC]){
            planStepList.add(planStepObject);
        }

        for(Case_Step__c caseStepObjt : [Select Id, Name,PlanStepOrder__c, IsCompleted__c, Is_Pending__c,Associated_Status__c,Flow_By_User__c, Case__c, Plan_Step__c From Case_Step__c Where Case__c =: recordId AND (Flow_By_User__c != null OR Plan_Step__c IN : planStepList) AND Associated_Status__c =: caseRecords[0].Status  ORDER BY PlanStepOrder__c ASC]){
            /*for(Plan_Step__c planStepObj : planStepList){
                if(caseStepObjt.Plan_Step__c == planStepObj.Id){
                    planStepAndCaseStepMap.put(planStepObj,caseStepObjt);
                }else{

                }
            }*/
            caseStepList.add(caseStepObjt);
        }
        for(Case_Step__c caseStepObject : caseStepList){
            flag = false;
            for(Plan_Step__c planStepObj : planStepList){
                if(caseStepObject.Plan_Step__c == planStepObj.Id && !flag){
                    caseStepWrpobj = new caseStepWrapper();
                    caseStepWrpobj.StepName =  planStepObj.Name;
                    caseStepWrpobj.AssociateStatus = planStepObj.Associate_Case_Status__c;
                    caseStepWrpobj.IsRequired   = planStepObj.Is_Required__c;
                    caseStepWrpobj.StepFlow = planStepObj.Flow__c;
                    caseStepWrpobj.PlanStepId = planStepObj.Id;
                    caseStepWrpobj.StartWhen = planStepObj.Start_When__c;
                    caseStepWrpobj.CaseStepId = caseStepObject.Id;
                    caseStepWrpobj.IsCompleted = caseStepObject.IsCompleted__c;
                    caseStepWrpobj.IsPending = caseStepObject.Is_Pending__c;
                    caseManagerRecord.caseStepWraperList.add(caseStepWrpobj);
                    flag = true;
                }
            }
            if(!flag){
                caseStepWrpobj = new caseStepWrapper();
                caseStepWrpobj.StepName =  caseStepObject.Name;
                caseStepWrpobj.AssociateStatus = caseStepObject.Associated_Status__c;
                caseStepWrpobj.IsRequired   = false;
                caseStepWrpobj.StepFlow = caseStepObject.Flow_By_User__c;
                caseStepWrpobj.PlanStepId = null;
                caseStepWrpobj.StartWhen = 'None';
                caseStepWrpobj.CaseStepId = caseStepObject.Id;
                caseStepWrpobj.IsCompleted = caseStepObject.IsCompleted__c;
                caseStepWrpobj.IsPending = caseStepObject.Is_Pending__c;
                caseManagerRecord.caseStepWraperList.add(caseStepWrpobj);
            }

        }
        caseManagerRecord.recordCasePlan = [SELECT Name, Id, CaseStatusOrdering__c, RecordType_SupportProcess__c, RecordTypeId__c FROM Case_Plan__c WHERE Id =: caseRecords[0].Case_Plan__c];


        return caseManagerRecord;
    }
    
    
    @InvocableMethod
    public static List<String> fetchRecordTypePicklistValue(List<String> RecordIdList){
        List<String> orderStatusStringList = new List<String>();
        //Map<String, Case_Plan_Support_Process__c> mcs = Case_Plan_Support_Process__c.getAll();
        //Case_Plan_Support_Process__c mc = Case_Plan_Support_Process__c.getValues();
        
        
        //String caserecord =  [Select Id, RecordTypeId from Case where Id IN :  RecordIdList LIMIT 1].RecordTypeId;
        String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
        String restAPIURL = sfdcURL + '/services/data/v45.0/ui-api/object-info/Case/picklist-values/' +RecordIdList[0];
        caseMgmt_JSON2Apex myWrapper;
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('GET');
        PageReference pg = new PageReference('/Apex/SessionIdUtilityPage');
        String sessionId ='';
        If(!test.isRunningTest()){
            sessionId = pg.getContent().toString().substringBetween('<div id="apiSeesionID">','</div>').trim();
        }
        
        //System.debug('SD: --> ' + pg.getContent().toString());
        System.debug('SD: ' + sessionId);
        httpRequest.setHeader('Authorization', 'OAuth ' + sessionId);
        System.debug('URL >>> ' + restAPIURL);
        httpRequest.setHeader('Authorization', 'Bearer ' + sessionId);
        httpRequest.setEndpoint(restAPIURL);
        String response = '';
        String orderString;
        try {
            If(!test.isRunningTest()){
                Http http = new Http();
                HttpResponse httpResponse = http.send(httpRequest);
                if (httpResponse.getStatusCode() == 200 ) {
                    response = JSON.serializePretty( JSON.deserializeUntyped(httpResponse.getBody()) );
                    caseMgmt_JSON2Apex selectedCse =  caseMgmt_JSON2Apex.parse(httpResponse.getBody());
                    List<caseMgmt_JSON2Apex.values> listOfStatus = selectedCse.picklistFieldValues.Status.Values;
                    for(caseMgmt_JSON2Apex.values value : listOfStatus){
                        if(orderString == null){
                            orderString = String.valueOf(value.value);
                        }else{
                            orderString = orderString + ';' + String.valueOf(value.value);
                        }
                    }
                    orderStatusStringList.add(orderString);
                } else {
                    System.debug(' httpResponse ' + httpResponse.getBody() );
                    throw new CalloutException( httpResponse.getBody() );
                }
            }
        } catch( System.Exception e) {
            System.debug('ERROR: '+ e);
            throw e;
        }
        return orderStatusStringList;
    }
    
    public class CaseManager{
        @auraEnabled public List<CaseMgmt_CasePlanController.caseStepWrapper> caseStepWraperList;
        @auraEnabled public String CaseStatus;
        @auraEnabled public Case_Plan__c recordCasePlan;
        public CaseManager(){
            caseStepWraperList = new List<CaseMgmt_CasePlanController.caseStepWrapper>();
            CaseStatus = '';
            recordCasePlan = new Case_Plan__c();
        }
    }
    public class caseStepWrapper{
        @auraEnabled public String StepName;
        @auraEnabled public String StepFlow;
        @auraEnabled public Boolean IsPending;
        @auraEnabled public Boolean IsCompleted;
        @auraEnabled public Boolean IsRequired;
        @auraEnabled public String AssociateStatus;
        @auraEnabled public String CaseStepId;
        @auraEnabled public String PlanStepId;
        @auraEnabled public String StartWhen;
    }
}