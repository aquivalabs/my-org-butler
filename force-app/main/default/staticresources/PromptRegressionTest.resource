<?xml version="1.0" encoding="UTF-8"?>
<AiTestingDefinition xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Prompt template smoke tests</description>
    <name>PromptRegression</name>
    <subjectName>MyOrgButler</subjectName>
    <subjectType>AGENT</subjectType>
    <!-- Single-turn depth only: the NGT metadata format cannot execute sequential turns,
         so the multi-turn ConsolidateMemory semantics (conflict resolution, deduplication)
         remain covered by prompt-regression.yaml over the REST runner. -->
    <testCase>
        <number>1</number>
        <inputs>
            <utterance>remember that I prefer opportunities sorted by Amount descending</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;StoreCustomInstruction&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Confirms the preference about sorting opportunities by Amount descending was stored</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>2</number>
        <inputs>
            <utterance>What email address do you have on file for me, and what else do you know about me?</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>States the user email address is rsoesemann@aquivalabs.com and surfaces further loaded context such as the saved preference to include StageName when listing opportunities</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>3</number>
        <inputs>
            <utterance>Check the proposal attached to the Acme Q1 Expansion Deal and tell me how many employees the user training covers</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;IdentifyRecordByName&apos;,&apos;GetRecordDetails&apos;,&apos;AnswerWithCurrentFile&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>States the user training covers up to 200 employees</expectedValue>
        </scorer>
    </testCase>
</AiTestingDefinition>
