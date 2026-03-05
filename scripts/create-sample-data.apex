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


// OPPORTUNITIES
// Designed with variance for Data Cloud pipeline insights demos:
// - Diverse LeadSource values for source analysis
// - Spread of close dates (past, this month, future) for pipeline timing
// - Varied stages across the funnel
// - Range of amounts for value analysis
// Note: LastStageChangeDate is auto-set by Salesforce. For stale deal demos,
// records need to age in the org (or adjust the threshold in the query).

List<Opportunity> opps = new List<Opportunity>();

// --- ACME CORPORATION (4 opportunities) ---

// HIGH PRIORITY: Closes in 3 days, $500k - Agent SHOULD prioritize this
opps.add(new Opportunity(
    Name = 'Acme Q1 Expansion Deal',
    AccountId = acme.Id,
    Amount = 500000,
    StageName = 'Negotiation',
    CloseDate = Date.today().addDays(3),
    LeadSource = 'Partner Referral',
    Description = 'Critical deal for Q1 targets, requires executive follow-up. Customer ready to sign.'
));

// MEDIUM: Closes in 2 weeks, $150k
opps.add(new Opportunity(
    Name = 'Acme Annual License Renewal',
    AccountId = acme.Id,
    Amount = 150000,
    StageName = 'Proposal',
    CloseDate = Date.today().addDays(14),
    LeadSource = 'Web',
    Description = 'Standard annual renewal. Good relationship with champion.'
));

// LOW: Closes in 3 months, exploratory
opps.add(new Opportunity(
    Name = 'Acme Cloud Migration Project',
    AccountId = acme.Id,
    Amount = 800000,
    StageName = 'Discovery',
    CloseDate = Date.today().addDays(90),
    LeadSource = 'Trade Show',
    Description = 'Long-term strategic initiative. Still in early discovery phase.'
));

// CLOSED WON: Past deal for historical analysis
opps.add(new Opportunity(
    Name = 'Acme Security Audit Package',
    AccountId = acme.Id,
    Amount = 120000,
    StageName = 'Closed Won',
    CloseDate = Date.today().addDays(-45),
    LeadSource = 'Web',
    Description = 'Completed security audit engagement. Customer very satisfied.'
));

// --- TECHSTART INDUSTRIES (3 opportunities) ---

opps.add(new Opportunity(
    Name = 'TechStart Platform Implementation',
    AccountId = techStart.Id,
    Amount = 75000,
    StageName = 'Qualification',
    CloseDate = Date.today().addDays(30),
    LeadSource = 'Phone Inquiry',
    Description = 'New customer interested in full platform deployment.'
));

opps.add(new Opportunity(
    Name = 'TechStart Analytics Add-On',
    AccountId = techStart.Id,
    Amount = 35000,
    StageName = 'Proposal',
    CloseDate = Date.today().addDays(10),
    LeadSource = 'Web',
    Description = 'Upsell analytics module to existing TechStart engagement.'
));

opps.add(new Opportunity(
    Name = 'TechStart Data Integration',
    AccountId = techStart.Id,
    Amount = 180000,
    StageName = 'Discovery',
    CloseDate = Date.today().addDays(120),
    LeadSource = 'Partner Referral',
    Description = 'Integration project connecting TechStart systems with Salesforce.'
));

// --- GLOBAL MANUFACTURING CORP (4 opportunities) ---

opps.add(new Opportunity(
    Name = 'Global Mfg Pilot Program',
    AccountId = globalMfg.Id,
    Amount = 50000,
    StageName = 'Proposal',
    CloseDate = Date.today().addDays(21),
    LeadSource = 'Trade Show',
    Description = 'Pilot program for one manufacturing plant. Success leads to enterprise rollout.'
));

opps.add(new Opportunity(
    Name = 'Global Mfg Enterprise Rollout',
    AccountId = globalMfg.Id,
    Amount = 2500000,
    StageName = 'Discovery',
    CloseDate = Date.today().addDays(180),
    LeadSource = 'Trade Show',
    Description = 'Full enterprise deployment across all 15 plants. Dependent on pilot success.'
));

opps.add(new Opportunity(
    Name = 'Global Mfg IoT Sensor Platform',
    AccountId = globalMfg.Id,
    Amount = 340000,
    StageName = 'Negotiation',
    CloseDate = Date.today().addDays(7),
    LeadSource = 'Phone Inquiry',
    Description = 'IoT sensor monitoring for Chicago plant floor. Procurement approved.'
));

// CLOSED LOST: Demonstrates pipeline attrition
opps.add(new Opportunity(
    Name = 'Global Mfg Supply Chain Optimization',
    AccountId = globalMfg.Id,
    Amount = 600000,
    StageName = 'Closed Lost',
    CloseDate = Date.today().addDays(-30),
    LeadSource = 'Email',
    Description = 'Lost to competitor. Budget was reallocated to internal project.'
));

// --- BURLINGTON TEXTILES (4 opportunities) ---

opps.add(new Opportunity(
    Name = 'Burlington Textiles Weaving Plant Generator',
    AccountId = burlington.Id,
    Amount = 235000,
    StageName = 'Id. Decision Makers',
    CloseDate = Date.today().addDays(60),
    LeadSource = 'Partner Referral',
    Description = 'Generator installation for new weaving plant expansion.'
));

opps.add(new Opportunity(
    Name = 'Burlington ERP Modernization',
    AccountId = burlington.Id,
    Amount = 950000,
    StageName = 'Qualification',
    CloseDate = Date.today().addDays(45),
    LeadSource = 'Email',
    Description = 'Legacy ERP replacement. CIO is executive sponsor.'
));

opps.add(new Opportunity(
    Name = 'Burlington Warehouse Automation',
    AccountId = burlington.Id,
    Amount = 425000,
    StageName = 'Proposal',
    CloseDate = Date.today().addDays(28),
    LeadSource = 'Trade Show',
    Description = 'Automating warehouse operations for Burlington distribution center.'
));

// CLOSED WON: Past deal
opps.add(new Opportunity(
    Name = 'Burlington Quality Control System',
    AccountId = burlington.Id,
    Amount = 88000,
    StageName = 'Closed Won',
    CloseDate = Date.today().addDays(-15),
    LeadSource = 'Phone Inquiry',
    Description = 'Quality control monitoring system for textile production lines.'
));

insert opps;