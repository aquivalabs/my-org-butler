Profile serviceAgentProfile = [SELECT Id FROM Profile WHERE Name = 'Einstein Agent User' LIMIT 1];
User serviceAgentUser = new User(
    FirstName = 'Service',
    LastName = 'Agent',
    Email = 'service.agent@example.com',
    Username = 'service.agent@example.com',
    Alias = 'agent1',
    TimeZoneSidKey = 'America/Denver',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US',
    profileId = serviceAgentProfile.Id
);
insert serviceAgentUser;