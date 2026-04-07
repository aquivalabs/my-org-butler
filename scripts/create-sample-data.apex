// AGENT TEST DATA SETUP
// Creates minimal demo data for conference talks and agent regression tests.
// Every record here serves a specific test or demo purpose — nothing extra.

// First: Delete ALL old Salesforce sample data
delete [SELECT Id FROM Task];
delete [SELECT Id FROM Opportunity];
delete [SELECT Id FROM Case];
delete [SELECT Id FROM Contact];
delete [SELECT Id FROM Entitlement];
delete [SELECT Id FROM Account WHERE Name != 'My Org Butler'];
delete [SELECT Id FROM ContentDocument WHERE Title IN ('Sample Company Document', 'Acme Q1 Expansion Proposal')];


// ACCOUNTS

Account acme = new Account(
    Name = 'Acme Corporation',
    BillingCity = 'New York',
    BillingCountry = 'USA',
    Industry = 'Technology',
    NumberOfEmployees = 5000,
    AnnualRevenue = 500000000,
    Description = 'Global technology leader founded in 1985. Key partner for enterprise software solutions.'
);
insert acme;

Account burlington = new Account(
    Name = 'Burlington Textiles Corp of America',
    BillingCity = 'Burlington',
    BillingCountry = 'USA',
    Industry = 'Apparel',
    NumberOfEmployees = 9000,
    AnnualRevenue = 350000000,
    Description = 'Leading textile manufacturer with 50+ years of industry experience.'
);
insert burlington;

Account stark = new Account(
    Name = 'Stark Industries',
    BillingCity = 'Los Angeles',
    BillingCountry = 'USA',
    Industry = 'Technology',
    NumberOfEmployees = 8000,
    AnnualRevenue = 750000000,
    Description = 'Defense and technology conglomerate specializing in advanced AI systems, robotics, and clean energy.'
);
insert stark;


// OPPORTUNITIES
// Note: Close dates use Date.today() so the "which opp should I work on next?" question
// always has a clear winner regardless of when the scratch org is created.

// Note: The clear #1 priority — highest amount + soonest close = agent must pick this
Opportunity acmeExpansion = new Opportunity(
    Name = 'Acme Q1 Expansion Deal',
    AccountId = acme.Id,
    Amount = 500000,
    StageName = 'Negotiation',
    CloseDate = Date.today().addDays(3),
    Description = 'Critical deal for Q1 targets, requires executive follow-up. Customer ready to sign.'
);
insert acmeExpansion;

// Note: For the task creation test (Testing Center #4)
Opportunity burlingtonDeal = new Opportunity(
    Name = 'Burlington Textiles Weaving Plant Generator',
    AccountId = burlington.Id,
    Amount = 235000,
    StageName = 'Id. Decision Makers',
    CloseDate = Date.today().addDays(60),
    Description = 'Generator installation for new weaving plant expansion.'
);
insert burlingtonDeal;

// SEMANTIC SEARCH DEMO DATA
// Note: These demonstrate SOQL vs hybrid_search() contrast (CzechDreamin Tip 3)
// - "Stark LLM Ops" = semantic match for "AI" (LLM relates to AI, no literal "AI" in name)
// - "Acme AI Platform" = keyword + semantic match
// - "Dubai Dreamin'" = SOQL false positive (LIKE '%AI%' matches "Dubai")

Opportunity starkLlm = new Opportunity(
    Name = 'Stark LLM Ops Automation',
    AccountId = stark.Id,
    Amount = 320000,
    StageName = 'Proposal',
    CloseDate = Date.today().addDays(45),
    Description = 'Large language model operations platform for automating internal workflows. Includes GPT-based document processing, neural network inference pipelines, and machine learning model deployment.'
);
insert starkLlm;

Opportunity acmeAi = new Opportunity(
    Name = 'Acme AI Platform Renewal',
    AccountId = acme.Id,
    Amount = 200000,
    StageName = 'Negotiation',
    CloseDate = Date.today().addDays(10),
    Description = 'Annual renewal of the Acme artificial intelligence and machine learning platform. Covers predictive analytics, natural language processing, and computer vision modules.'
);
insert acmeAi;

Opportunity dubaiSponsoring = new Opportunity(
    Name = 'Dubai Dreamin\' Sponsoring',
    AccountId = acme.Id,
    Amount = 15000,
    StageName = 'Closed Won',
    CloseDate = Date.today().addDays(-30),
    Description = 'Gold sponsorship of the Dubai Dreamin\' Salesforce community conference. Includes booth, speaking slot, and logo placement.'
);
insert dubaiSponsoring;


// CUSTOM SETTINGS
List<CustomSetting__c> existing = [SELECT Id FROM CustomSetting__c WHERE Name = 'DataLibraryRetriever'];
if(existing.isEmpty()) {
    insert as user new CustomSetting__c(Name = 'DataLibraryRetriever', Value__c = 'MyOrgButlerLibrary');
} else {
    existing[0].put('Value__c', 'MyOrgButlerLibrary');
    update as user existing;
}