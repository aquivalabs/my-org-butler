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
            <utterance>tell me what you know about me</utterance>
        </inputs>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Surfaces stored user context such as name, email, timezone or saved preferences, not just a generic statement</expectedValue>
        </scorer>
    </testCase>
    <testCase>
        <number>3</number>
        <inputs>
            <utterance>the Acme Q1 Expansion Deal has a PDF file attached, what is the total contract value and how is it split across phases?</utterance>
        </inputs>
        <scorer>
            <name>action_sequence_match</name>
            <expectedValue>[&apos;LoadCustomInstructions&apos;,&apos;IdentifyRecordByName&apos;,&apos;GetRecordDetails&apos;,&apos;AnswerWithCurrentFile&apos;]</expectedValue>
        </scorer>
        <scorer>
            <name>bot_response_rating</name>
            <expectedValue>Mentions $500,000 total and references the three payments: $125,000 at contract signing, $125,000 at delivery milestone, $250,000 at go-live</expectedValue>
        </scorer>
    </testCase>
</AiTestingDefinition>
