@IsTest
private class LeadScoring_Test {


    @IsTest
    private static void scoresMaxOnInsert() {

        // Setup
        enterpriseQueue();

        // Exercise
        insert lead('Technology', 1000, 'High');

        // Verify
        Assert.areEqual(100, [SELECT LeadScore__c FROM Lead LIMIT 1].LeadScore__c);
    }


    @IsTest
    private static void scoresZeroForBlankInputs() {

        // Setup
        enterpriseQueue();

        // Exercise
        insert lead(null, null, null);

        // Verify
        Assert.areEqual(0, [SELECT LeadScore__c FROM Lead LIMIT 1].LeadScore__c);
    }


    @IsTest
    private static void doesNotRouteAt69() {

        // Setup
        Group queue = enterpriseQueue();

        // Exercise — Technology(40) + 99 employees(9) + Medium(20) = 69
        insert lead('Technology', 99, 'Medium');

        // Verify
        Lead result = [SELECT LeadScore__c, OwnerId FROM Lead LIMIT 1];
        Assert.areEqual(69, result.LeadScore__c);
        Assert.areNotEqual(queue.Id, result.OwnerId);
    }


    @IsTest
    private static void routesAt70() {

        // Setup
        Group queue = enterpriseQueue();

        // Exercise — Technology(40) + null employees(0) + High(30) = 70
        insert lead('Technology', null, 'High');

        // Verify
        Lead result = [SELECT LeadScore__c, OwnerId FROM Lead LIMIT 1];
        Assert.areEqual(70, result.LeadScore__c);
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
        testLead.EmailEngagement__c = 'High';
        update testLead;

        // Verify
        Lead result = [SELECT LeadScore__c, OwnerId FROM Lead WHERE Id = :testLead.Id];
        Assert.areEqual(100, result.LeadScore__c);
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
        List<Lead> results = [SELECT LeadScore__c FROM Lead];
        Assert.areEqual(200, results.size());
        for(Lead result : results) {
            Assert.areEqual(100, result.LeadScore__c);
        }
    }


    // HELPER

    private static Lead lead(String industry, Integer employees, String engagement) {
        Lead result = new Lead();
        result.LastName = 'Test';
        result.Company = 'Acme';
        result.Industry = industry;
        result.NumberOfEmployees = employees;
        result.EmailEngagement__c = engagement;
        return result;
    }

    private static Group enterpriseQueue() {
        Group result = null;
        for(Group q : [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Enterprise' LIMIT 1]) {
            result = q;
        }
        Assert.isNotNull(result, 'Enterprise queue must be deployed before running tests');
        return result;
    }
}
