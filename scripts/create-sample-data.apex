// AGENT TEST DATA SETUP
// Creates realistic demo data for conference talks and agent regression tests

// First: Delete ALL old Salesforce sample data (United Oil, Edge, Grand Hotels, etc.)
// This ensures only OUR demo data exists for clean conference demos
delete [SELECT Id FROM Task];
delete [SELECT Id FROM Opportunity];
delete [SELECT Id FROM Case];
delete [SELECT Id FROM Contact];
delete [SELECT Id FROM Account WHERE Name != 'My Org Butler'];
delete [SELECT Id FROM ContentDocument WHERE Title = 'Acme Corporation NDA 2026'];


// ACCOUNT 1: Acme Corporation - Primary demo account
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

// ACCOUNT 2: TechStart Industries - Growing startup
Account techStart = new Account(
    Name = 'TechStart Industries',
    BillingCity = 'San Francisco',
    BillingCountry = 'USA',
    Industry = 'Technology',
    NumberOfEmployees = 150,
    AnnualRevenue = 25000000,
    Description = 'Fast-growing B2B SaaS startup focused on workflow automation.'
);
insert techStart;

// ACCOUNT 3: Global Manufacturing Corp - Traditional enterprise
Account globalMfg = new Account(
    Name = 'Global Manufacturing Corp',
    BillingCity = 'Chicago',
    BillingCountry = 'USA',
    Industry = 'Manufacturing',
    NumberOfEmployees = 12000,
    AnnualRevenue = 2000000000,
    Description = 'Fortune 500 manufacturing company with global operations.'
);
insert globalMfg;

// ACCOUNT 4: Burlington Textiles - Standard Salesforce demo company
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


// OPPORTUNITIES FOR ACME (Primary demo account)

// HIGH PRIORITY: Closes in 3 days, $500k - Agent SHOULD prioritize this
Opportunity acmeUrgent = new Opportunity(
    Name = 'Acme Q1 Expansion Deal',
    AccountId = acme.Id,
    Amount = 500000,
    StageName = 'Negotiation',
    CloseDate = Date.today().addDays(3),
    Description = 'Critical deal for Q1 targets, requires executive follow-up. Customer ready to sign.'
);
insert acmeUrgent;

// MEDIUM: Closes in 2 weeks, $150k
Opportunity acmeRenewal = new Opportunity(
    Name = 'Acme Annual License Renewal',
    AccountId = acme.Id,
    Amount = 150000,
    StageName = 'Proposal',
    CloseDate = Date.today().addDays(14),
    Description = 'Standard annual renewal. Good relationship with champion.'
);
insert acmeRenewal;

// LOW: Closes in 3 months, exploratory
Opportunity acmeFuture = new Opportunity(
    Name = 'Acme Cloud Migration Project',
    AccountId = acme.Id,
    Amount = 800000,
    StageName = 'Discovery',
    CloseDate = Date.today().addDays(90),
    Description = 'Long-term strategic initiative. Still in early discovery phase.'
);
insert acmeFuture;


// OPPORTUNITIES FOR TECHSTART

Opportunity techStartDeal = new Opportunity(
    Name = 'TechStart Platform Implementation',
    AccountId = techStart.Id,
    Amount = 75000,
    StageName = 'Qualification',
    CloseDate = Date.today().addDays(30),
    Description = 'New customer interested in full platform deployment.'
);
insert techStartDeal;


// OPPORTUNITIES FOR GLOBAL MANUFACTURING

Opportunity globalMfgPilot = new Opportunity(
    Name = 'Global Mfg Pilot Program',
    AccountId = globalMfg.Id,
    Amount = 50000,
    StageName = 'Proposal',
    CloseDate = Date.today().addDays(21),
    Description = 'Pilot program for one manufacturing plant. Success leads to enterprise rollout.'
);
insert globalMfgPilot;

Opportunity globalMfgEnterprise = new Opportunity(
    Name = 'Global Mfg Enterprise Rollout',
    AccountId = globalMfg.Id,
    Amount = 2500000,
    StageName = 'Discovery',
    CloseDate = Date.today().addDays(180),
    Description = 'Full enterprise deployment across all 15 plants. Dependent on pilot success.'
);
insert globalMfgEnterprise;


// OPPORTUNITY FOR BURLINGTON TEXTILES
Opportunity burlingtonDeal = new Opportunity(
    Name = 'Burlington Textiles Weaving Plant Generator',
    AccountId = burlington.Id,
    Amount = 235000,
    StageName = 'Id. Decision Makers',
    CloseDate = Date.today().addDays(60),
    Description = 'Generator installation for new weaving plant expansion.'
);
insert burlingtonDeal;