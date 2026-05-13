@IsTest
private class LeadScoring_Test {


    @IsTest
    private static void scoresMaxOnInsert() {

        // Setup
        enterpriseQueue();

        // Exercise
        insert lead('Technology', 1000, 'High');

        // Verify
        Assert.areEqual(100, [SELECT Lead_Score__c FROM Lead LIMIT 1].Lead_Score__c);
    }


    @IsTest
    private static void scoresZeroForBlankInputs() {

        // Setup
        enterpriseQueue();

        // Exercise
        insert lead(null, null, null);

        // Verify
        Assert.areEqual(0, [SELECT Lead_Score__c FROM Lead LIMIT 1].Lead_Score__c);
    }


    @IsTest
    private static void doesNotRouteAt69() {

        // Setup
        Group queue = enterpriseQueue();

        // Exercise — Technology(40) + 99 employees(9) + Medium(20) = 69
        insert lead('Technology', 99, 'Medium');

        // Verify
        Lead result = [SELECT Lead_Score__c, OwnerId FROM Lead LIMIT 1];
        Assert.areEqual(69, result.Lead_Score__c);
        Assert.areNotEqual(queue.Id, result.OwnerId);
    }


    @IsTest
    private static void routesAt70() {

        // Setup
        Group queue = enterpriseQueue();

        // Exercise — Technology(40) + null employees(0) + High(30) = 70
        insert lead('Technology', null, 'High');

        // Verify
        Lead result = [SELECT Lead_Score__c, OwnerId FROM Lead LIMIT 1];
        Assert.areEqual(70, result.Lead_Score__c);
        Assert.areEqual(queue.Id, result.OwnerId);
    }


    @IsTest
    private static void recalculatesOnUpdate() {

        // Setup
        Group queue = enterpriseQueue();
        Lead testLead = lead(null, null, null);
        insert testLead;

        // Exercise
        testLead.Industry = 'Technology';
        testLead.NumberOfEmployees = 1000;
        testLead.Email_Engagement__c = 'High';
        update testLead;

        // Verify
        Lead result = [SELECT Lead_Score__c, OwnerId FROM Lead WHERE Id = :testLead.Id];
        Assert.areEqual(100, result.Lead_Score__c);
        Assert.areEqual(queue.Id, result.OwnerId);
    }


    @IsTest
    private static void bulk200Leads() {

        // Setup
        enterpriseQueue();
        List<Lead> leads = new List<Lead>();
        for(Integer i = 0; i < 200; i++) {
            leads.add(lead('Technology', 1000, 'High'));
        }

        // Exercise
        insert leads;

        // Verify
        List<Lead> results = [SELECT Lead_Score__c FROM Lead];
        Assert.areEqual(200, results.size());
        for(Lead result : results) {
            Assert.areEqual(100, result.Lead_Score__c);
        }
    }


    // HELPER

    private static Lead lead(String industry, Integer employees, String engagement) {
        Lead result = new Lead();
        result.LastName = 'Test';
        result.Company = 'Acme';
        result.Industry = industry;
        result.NumberOfEmployees = employees;
        result.Email_Engagement__c = engagement;
        return result;
    }

    private static Group enterpriseQueue() {
        Group result = new Group(Name = 'Enterprise', Type = 'Queue');
        for(Group q : [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Enterprise' LIMIT 1]) {
            result = q;
        }
        if(result.Id == null) {
            // Note: runAs isolates setup-object DML so it doesn't mix with Lead DML
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert result;
                insert new QueueSObject(QueueId = result.Id, SObjectType = 'Lead');
            }
        }
        return result;
    }
}
