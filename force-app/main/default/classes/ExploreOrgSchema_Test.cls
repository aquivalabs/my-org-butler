@IsTest
private class ExploreOrgSchema_Test {
    
    @IsTest
    private static void allObjects() {

        // Setup
        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'allObjects';
        
        // Exercise
        List<ExploreOrgSchema.Output> results = ExploreOrgSchema.investigateSchema(new List<ExploreOrgSchema.Input>{ input });
        
        // Verify
        System.assertNotEquals(null, results[0].response);
        List<String> lines = results[0].response.split('\n');
        System.assert(!lines.isEmpty());
    }

    @IsTest
    private static void objectDetails() {

        // Setup
        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'objectDetails';
        input.objects = 'Account';

        // Exercise
        List<ExploreOrgSchema.Output> results = ExploreOrgSchema.investigateSchema(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        System.assertNotEquals(null, results[0].response);
        List<String> lines = results[0].response.split('\n');
        System.assert(!lines.isEmpty());
        
        String nameLine = null;
        for(String line : lines) {
            if(line.startsWith('Name (')) {
                nameLine = line;
                break;
            }
        }
        System.assertNotEquals(null, nameLine);
        System.assert(nameLine.contains('STRING'));
    }

    @IsTest 
    private static void objectDetailsWithRelationship() {

        // Setup
        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'objectDetails';
        input.objects = 'Contact';

        // Exercise
        List<ExploreOrgSchema.Output> results = ExploreOrgSchema.investigateSchema(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        System.assertNotEquals(null, results[0].response);
        List<String> lines = results[0].response.split('\n');
        
        String accountIdLine = null;
        for(String line : lines) {
            if(line.startsWith('AccountId (')) {
                accountIdLine = line;
                break;
            }
        }
        
        System.assertNotEquals(null, accountIdLine);
        List<String> parts = accountIdLine.split('\t');
        System.assertEquals('REFERENCE', parts[1]);
        System.assertEquals('Account', parts[2]);
        System.assertEquals('Account', parts[3]);
    }

    @IsTest
    private static void multipleSpecificObjects() {

        // Setup
        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'objectDetails';  // Changed from 'specificObject' to 'objectDetails'
        input.objects = 'Account,Contact';
        
        // Exercise
        List<ExploreOrgSchema.Output> results = ExploreOrgSchema.investigateSchema(new List<ExploreOrgSchema.Input>{ input });
        
        // Verify
        String response = results[0].response;
        System.assert(response.contains('Object: Account (' ));
        System.assert(response.contains('Object: Contact (' ));
    }

    @IsTest
    private static void invalidScope() {
        // Setup
        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'invalidScope';
        input.objects = 'Account';
        
        // Exercise
        try {
            ExploreOrgSchema.investigateSchema(new List<ExploreOrgSchema.Input>{ input });
            System.assert(false, 'Should have thrown an exception');
        } catch(ApplicationException e) {
            // Verify
            System.assertEquals('Invalid scope value. Must be either "allObjects" or "objectDetails".', e.getMessage());
        }
    }

    @IsTest
    private static void objectDetailsWithPicklist() {
        // Setup
        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'objectDetails';
        input.objects = 'Account';

        // Exercise
        List<ExploreOrgSchema.Output> results = ExploreOrgSchema.investigateSchema(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        System.assertNotEquals(null, results[0].response);
        List<String> lines = results[0].response.split('\n');
        
        String industryLine = null;
        for(String line : lines) {
            if(line.startsWith('Industry (')) {
                industryLine = line;
                break;
            }
        }
        
        System.assertNotEquals(null, industryLine);
        System.assert(industryLine.contains('PICKLIST'));
        System.assert(industryLine.contains('Agriculture'));  // A known Industry picklist value
    }
}