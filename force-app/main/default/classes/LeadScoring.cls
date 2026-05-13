public with sharing class LeadScoring {

    private static final Set<String> HIGH_INDUSTRY = new Set<String>{
        'Technology', 'Finance', 'Financial Services'
    };
    private static final Set<String> MID_INDUSTRY = new Set<String>{
        'Healthcare', 'Biotechnology', 'Pharmaceuticals', 'Manufacturing', 'Energy'
    };

    private List<Lead> leads;


    // CONSTRUCTOR

    public LeadScoring(List<Lead> leads) {
        this.leads = leads;
    }


    // PUBLIC

    public void score() {
        Id queueId = enterpriseQueueId();
        for(Lead lead : leads) {
            Integer points = industryPoints(lead) + sizePoints(lead) + engagementPoints(lead);
            lead.Lead_Score__c = points;
            if(queueId != null && points >= 70) {
                lead.OwnerId = queueId;
            }
        }
    }


    // PRIVATE

    private Id enterpriseQueueId() {
        Id result = null;
        for(Group q : [SELECT Id
                       FROM Group
                       WHERE Type = 'Queue'
                         AND Name = 'Enterprise'
                       WITH USER_MODE
                       LIMIT 1]) {
            result = q.Id;
        }
        return result;
    }

    private Integer industryPoints(Lead lead) {
        Integer result = 0;
        if(HIGH_INDUSTRY.contains(lead.Industry)) {
            result = 40;
        } else if(MID_INDUSTRY.contains(lead.Industry)) {
            result = 30;
        } else if(lead.Industry != null) {
            result = 10;
        }
        return result;
    }

    private Integer sizePoints(Lead lead) {
        Integer result = 0;
        if(lead.NumberOfEmployees != null) {
            if(lead.NumberOfEmployees >= 1000) {
                result = 30;
            } else if(lead.NumberOfEmployees >= 200) {
                result = 20;
            } else if(lead.NumberOfEmployees >= 50) {
                result = 9;
            }
        }
        return result;
    }

    private Integer engagementPoints(Lead lead) {
        Integer result = 0;
        if(lead.Email_Engagement__c == 'High') {
            result = 30;
        } else if(lead.Email_Engagement__c == 'Medium') {
            result = 20;
        } else if(lead.Email_Engagement__c == 'Low') {
            result = 10;
        }
        return result;
    }
}
