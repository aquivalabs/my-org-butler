@IsTest
private class ExploreOrgDataModel_Test {
    
    @IsTest
    private static void allObjects() {

        // Setup
        ExploreOrgDataModel.Input input = new ExploreOrgDataModel.Input();
        input.scope = 'allObjects';
        
        // Exercise
        List<ExploreOrgDataModel.Output> results = ExploreOrgDataModel.investigateSchema(new List<ExploreOrgDataModel.Input>{ input });
        
        // Verify
        System.assertNotEquals(null, results[0].response);
        List<String> lines = results[0].response.split('\n');
        System.assert(!lines.isEmpty());
    }

    @IsTest
    private static void objectDetails() {

        // Setup
        ExploreOrgDataModel.Input input = new ExploreOrgDataModel.Input();
        input.scope = 'objectDetails';
        input.objects = 'Account';

        // Exercise
        List<ExploreOrgDataModel.Output> results = ExploreOrgDataModel.investigateSchema(new List<ExploreOrgDataModel.Input>{ input });

        // Verify
        System.assertNotEquals(null, results[0].response);
        List<String> lines = results[0].response.split('\n');
        System.assert(!lines.isEmpty());
        
        String nameLine = null;
        for(String line : lines) {
            if(line.startsWith('Name\t')) {
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
        ExploreOrgDataModel.Input input = new ExploreOrgDataModel.Input();
        input.scope = 'objectDetails';
        input.objects = 'Contact';

        // Exercise
        List<ExploreOrgDataModel.Output> results = ExploreOrgDataModel.investigateSchema(new List<ExploreOrgDataModel.Input>{ input });

        // Verify
        System.assertNotEquals(null, results[0].response);
        List<String> lines = results[0].response.split('\n');
        
        String accountIdLine = null;
        for(String line : lines) {
            if(line.startsWith('AccountId\t')) {
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
        ExploreOrgDataModel.Input input = new ExploreOrgDataModel.Input();
        input.scope = 'objectDetails';  // Changed from 'specificObject' to 'objectDetails'
        input.objects = 'Account,Contact';
        
        // Exercise
        List<ExploreOrgDataModel.Output> results = ExploreOrgDataModel.investigateSchema(new List<ExploreOrgDataModel.Input>{ input });
        
        // Verify
        String response = results[0].response;
        System.assert(response.contains('Object: Account (' ));
        System.assert(response.contains('Object: Contact (' ));
    }

    @IsTest
    private static void invalidScope() {
        // Setup
        ExploreOrgDataModel.Input input = new ExploreOrgDataModel.Input();
        input.scope = 'invalidScope';
        input.objects = 'Account';
        
        // Exercise
        try {
            ExploreOrgDataModel.investigateSchema(new List<ExploreOrgDataModel.Input>{ input });
            System.assert(false, 'Should have thrown an exception');
        } catch(ApplicationException e) {
            // Verify
            System.assertEquals('Invalid scope value. Must be either "allObjects" or "objectDetails".', e.getMessage());
        }
    }

    @IsTest
    private static void objectDetailsWithPicklist() {
        // Setup
        ExploreOrgDataModel.Input input = new ExploreOrgDataModel.Input();
        input.scope = 'objectDetails';
        input.objects = 'Account';

        // Exercise
        List<ExploreOrgDataModel.Output> results = ExploreOrgDataModel.investigateSchema(new List<ExploreOrgDataModel.Input>{ input });

        // Verify
        System.assertNotEquals(null, results[0].response);
        List<String> lines = results[0].response.split('\n');
        
        String industryLine = null;
        for(String line : lines) {
            if(line.startsWith('Industry\t')) {
                industryLine = line;
                break;
            }
        }
        
        System.assertNotEquals(null, industryLine);
        System.assert(industryLine.contains('PICKLIST'));
        System.assert(industryLine.contains('Agriculture'));  // A known Industry picklist value
    }
}