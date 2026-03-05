@IsTest
private class ExploreDataCloudSchema_Test {

    @IsTest
    private static void execute() {

        // Setup - mock the metadata result
        Map<String, Object> mockMetadata = new Map<String, Object>{
            'ssot__Name__c' => new Map<String, Object>{ 'type' => 'VARCHAR', 'placeInOrder' => 0 },
            'ssot__CloseDate__c' => new Map<String, Object>{ 'type' => 'DATE', 'placeInOrder' => 1 },
            'ssot__CreatedDate__c' => new Map<String, Object>{ 'type' => 'TIMESTAMP', 'placeInOrder' => 2 }
        };
        ExploreDataCloudSchema.mockedResult = JSON.serialize(mockMetadata);

        // Exercise
        ExploreDataCloudSchema.Input input = new ExploreDataCloudSchema.Input();
        input.objectName = 'ssot__Opportunity__dlm';

        List<ExploreDataCloudSchema.Output> result = ExploreDataCloudSchema.execute(
            new List<ExploreDataCloudSchema.Input>{ input }
        );

        // Verify
        Assert.areEqual(1, result.size());
        Assert.isTrue(String.isNotBlank(result[0].resultOrException));

        Map<String, Object> metadata = (Map<String, Object>) JSON.deserializeUntyped(result[0].resultOrException);
        Assert.isTrue(metadata.containsKey('ssot__Name__c'));
        Assert.isTrue(metadata.containsKey('ssot__CloseDate__c'));
    }

    @IsTest
    private static void handleError() {

        // Setup - no mock, CdpQuery will throw in test context
        ExploreDataCloudSchema.mockedResult = null;

        // Exercise
        ExploreDataCloudSchema.Input input = new ExploreDataCloudSchema.Input();
        input.objectName = 'nonexistent__dlm';

        List<ExploreDataCloudSchema.Output> result = ExploreDataCloudSchema.execute(
            new List<ExploreDataCloudSchema.Input>{ input }
        );

        // Verify - should return exception JSON
        Assert.areEqual(1, result.size());
        Assert.isTrue(String.isNotBlank(result[0].resultOrException));

        Map<String, Object> exceptionResult = (Map<String, Object>) JSON.deserializeUntyped(result[0].resultOrException);
        Assert.isTrue(exceptionResult.containsKey('message'));
    }
}
