<?xml version="1.0" encoding="UTF-8"?>
<AiTestingDefinition xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Per-action regression for the agent</description>
    <name>AgentRegression</name>
    <subjectName>MyOrgButler</subjectName>
    <subjectType>AGENT</subjectType>
    <testCase>
        <number>1</number>
        <inputs>
            <utterance>the Acme Q1 Expansion Deal has a PDF file attached, open it and tell me the total contract value</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;IdentifyRecordByName&apos;,&apos;GetRecordDetails&apos;,&apos;AnswerWithCurrentFile&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>States the total contract value is 500,000</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>2</number>
        <inputs>
            <utterance>is there an approval process configured for Opportunities? use the Metadata API to check</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;CallMetadataApi&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Shows approval process details for Opportunity or states that no approval process is configured</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>3</number>
        <inputs>
            <utterance>use the REST API to create a new Task with Subject &quot;Call Burlington&quot; and Status &quot;Not Started&quot;</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;CallRestApi&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Confirms a Task record was created with subject containing Call Burlington</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>4</number>
        <inputs>
            <utterance>what is the Apex code coverage percentage in this org?</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;CallToolingApi&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Returns a specific code coverage percentage or lists coverage per class with percentages</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>5</number>
        <inputs>
            <utterance>create a PlantUML class diagram showing the typical Service Cloud objects, including their relationships</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;CreatePlantUmlUrl&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Returns a clickable PlantUML URL containing a class diagram of Service Cloud objects such as Case, Contact and Account with their relationships</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>6</number>
        <inputs>
            <utterance>what fields does the Memory__c object have and what are their types?</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;ExploreOrgSchema&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Lists fields of Memory__c including Content__c and IsShared__c</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>7</number>
        <inputs>
            <utterance>tell me what you know about me</utterance>
        </inputs>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Surfaces stored user context such as name, email, timezone or saved preferences, not just a greeting</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>8</number>
        <inputs>
            <utterance>send me a hello world notification</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;NotifyUser&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Confirms a notification containing the words hello world was sent</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>9</number>
        <inputs>
            <utterance>every weekday at 9am, check for opportunities closing this week and notify me</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;PlanForLater&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Confirms the plan was scheduled successfully and provides a link to the plan record</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>10</number>
        <inputs>
            <utterance>run a data cloud query to find the source filename of the PDF document in our data library</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;ExploreDataCloud&apos;,&apos;QueryDataCloud&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Returns &apos;policy.pdf&apos; as the source filename</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>11</number>
        <inputs>
            <utterance>which deal should I focus on? which is most urgent?</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;QueryRecordsWithSoql&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Recommends the Acme Q1 Expansion Deal as the opportunity to focus on</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>12</number>
        <inputs>
            <utterance>what is our company discount policy for deals over $100K? check the company docs</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;ExploreDataCloud&apos;,&apos;SearchDataLibrary&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Mentions that discounts above 10 percent require VP of Sales approval</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>13</number>
        <inputs>
            <utterance>where is Aquiva Labs located and when were they founded? search the web</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;SearchWeb&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Mentions Florida (Celebration or Orlando) as location and 2015 as founding year</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>14</number>
        <inputs>
            <utterance>remember that when I ask you to list opportunities, you should always include the StageName</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;StoreCustomInstruction&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Confirms it stored a preference to always include StageName when listing opportunities</expectedValue>
        </scorer>
    </testCase>
</AiTestingDefinition>
