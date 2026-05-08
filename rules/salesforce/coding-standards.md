---
paths:
  - "**/*.cls"
  - "**/*.trigger"
  - "**/*-meta.xml"
  - "force-app/**"
  - "unpackaged/**"
---

# Salesforce / Apex Coding Standards

## Verification

Many of these principles are enforced by a [custom PMD ruleset](../skills/sf-code-analyzer/pmd-ruleset.xml) via `/sf-code-analyzer`. **After creating or modifying any `.cls`, `.trigger`, or `*-meta.xml` file, run `/sf-code-analyzer` on the changed files before considering the task done.**

## Core Principles

### One Return Per Method

Methods have exactly one `return` statement at the end. Use the `result` variable pattern.

(Checked by custom PMD rule: [`OnlyOneReturnPerMethod`](../skills/sf-code-analyzer/pmd-ruleset.xml) and [`DeclareWhatYouReturnFirstAndCallItResult`](../skills/sf-code-analyzer/pmd-ruleset.xml))

```java
private List<Account> findAccounts(String name) {
    List<Account> result = new List<Account>();

    for(Account acc : accounts) {
        if(acc.Name.contains(name)) {
            result.add(acc);
        }
    }

    return result;
}
```

### No Forbidden Suffixes

Never use: `Service`, `Handler`, `Manager`, `Helper`, `Util`, `Wrapper`

These names hide intent. Use domain names that reveal what the class represents.

(Checked by custom PMD rule: [`ClassNamesBecomeSelfFulfillingProphecies`](../skills/sf-code-analyzer/pmd-ruleset.xml))

### Comments: When Forbidden, When Required

No formal JavaDoc/ApexDoc `/** */` comments. If code needs explanation, the code is unclear. Write clearer code. Write better tests.

However, there are exactly two exceptions where `// Note:` comments ARE required:

1. **Strange code that must be that way** — Code that violates normal conventions but is necessary. Explain why it's an exception.
2. **PMD suppressions** — Every `@SuppressWarnings` must have a `// Note:` comment explaining why the rule is being skipped.

(Checked by custom PMD rules: [`CommentsOftenExcuseForBadCodeAndTests`](../skills/sf-code-analyzer/pmd-ruleset.xml) and [`CheckIfProperFalsePositive`](../skills/sf-code-analyzer/pmd-ruleset.xml))

Examples:

```java
// Note: without sharing required to access org-wide data
public without sharing class ReportGenerator {
    ...
}

// Note: Input is required=true in schema — Agentforce won't call without it
@SuppressWarnings('PMD.MissingNullCheckOnSoqlVariable')
private static List<Account> fetchAccounts() { ... }
```

### Tests Don't Start With "test"

Never prefix a test method with `test`. It adds no information — the `@IsTest` annotation and `_Test` class suffix already say it's a test.

(Checked by custom PMD rule: [`TestsShouldNotStartWithTest`](../skills/sf-code-analyzer/pmd-ruleset.xml))

### Test Method Names: Match the Scope of What's Being Verified

The right name depends on how many tests the method under test has:

**One vanilla test per method → name it after the method.**
A single happy-path test for `execute()` should just be called `execute()`. Class + method reads `SearchDataLibrary_Test.execute` — which says exactly what it is. No need to invent descriptive prose for a test that covers one obvious behavior.

**Multiple tests per method → name by scenario, as short as possible.**
Once you need to distinguish cases, use the shortest name that differentiates them. Two or three words is usually enough.

- Good: `execute()`, `executeWithChunks()`, `executeWithoutChunks()`
- Good: `retrieves()`, `retrievesEmptyOnBadDmo()`
- Bad: `executeFallsBackToChunksOnlyWhenFullDocumentPromptFails()` — a prose essay. The test body is mostly mocking; the name shouldn't oversell it.
- Bad: `testExecute1()`, `testExecute2()` — numbered, meaningless, and starts with `test`.

**When a long descriptive name *is* warranted:**
Integration-style tests with real setup, exercising a non-obvious behavior worth calling out, can use sentence-style names (`returnsOverdueTasksFirst()`). The rule of thumb: the name's length should roughly match how much real behavior the test exercises. Heavy mocks → short name. Real data + real assertions → longer name is fine.

**Always:** one focused assertion (or a tightly related set). If you need a sentence to explain what the test does, the test is probably doing too much — split it.

### Use Salesforce Standards, Don't Reinvent

Don't invent workarounds for problems Salesforce already solved. Use the built-in features:



- Named Credentials (not Custom Settings for authentication)
- Platform Events (not custom polling mechanisms)
- Salesforce-native configuration over custom metadata

### Test Isolation — Every Test Stands Alone

Each test method must be completely isolated. No shared state, no global test variables, no `@TestSetup`.

Setup code belongs in the test method itself, called via a helper method:

```java
@IsTest
private class MyClass_Test {

    @IsTest
    private static void someTestBehavior() {

        // Setup
        setup();

        // Exercise
        ...

        // Verify
        ...
    }

    // HELPER

    private static void setup() {
        ...
    }
}
```

## Project Structure

```
force-app/
└── main/default/
    └── classes/                       # ALL your classes go here (flat structure)
```

Keep all classes together. Tests next to their subjects. No sub-packages.

## Coding Patterns

### Class Structure

Organize with ALL-CAPS section comments. Double blank lines between methods:

```java
public with sharing class ClassName {

    private static final String CONSTANT = 'value';

    private String field;


    // CONSTRUCTOR

    public ClassName() {
        // initialization
    }


    // PUBLIC

    public String process() {
        String result = doWork();

        return result;
    }


    // PRIVATE

    private String doWork() {
        String result = 'processed';

        return result;
    }


    // INNER

    public class InnerClass {
        public String value;
    }
}
```

### Test Structure

Three section comments only: `// Setup`, `// Exercise`, `// Verify`. No other comments in tests. Blank line before each section. Double blank lines between test methods:

```java
@IsTest
private class ClassName_Test {


    @IsTest
    private static void returnsExpectedValue() {

        // Setup
        Account acc = (Account) new Account_t().name('Acme').persist();


        // Exercise
        String actual = MyClass.process(acc);


        // Verify
        Assert.areEqual('expected', actual);
    }


    @IsTest
    private static void throwsExceptionForInvalidInput() {

        // Setup
        ...


        // Exercise
        ...


        // Verify
        ...
    }


    // HELPER

    private static Input createInput() {
        Input result = new Input();
        result.value = 'test';

        return result;
    }
}
```

### No Assertion Messages

Assertions have no message parameter. This is a red flag: if you need a message to explain what an assertion does, your test method is doing too much.

The test method name should fully describe what is being verified. One assertion per test, or a tightly related set. If you're writing assertion messages, break the test into smaller, more focused tests:

- Bad: `testUserCreation()` with `Assert.areEqual(user.status, 'active', 'User should have active status')`
  - Problem: One method testing multiple things (creation, status, ...)
  - Needs a message because the name doesn't say what's being verified

- Good: `createsUserWithActiveStatus()` with `Assert.areEqual('active', user.status)`
  - The method name is explicit. The assertion is obvious. No message needed.

### Method Chaining Alignment

Indent to align visually:

```java
String response = new PromptTemplate('ExtractTasks')
                            .call(new Map<String, Object>{
                                'Input:notes' => notes
                            });
```

### SOQL Formatting

Long queries: each field on its own line, aligned:

```java
List<Project__c> projects = [SELECT Id, Name,
                                    Status__c,
                                    StartDate__c,
                                    (SELECT Id, Name,
                                            OwnerId, Owner.Name
                                    FROM Tasks__r)
                            FROM Project__c
                            WHERE Id = :projectId
                            WITH USER_MODE];
```

### Invocable Actions

```java
// Note: Agentforce requires global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class VerbNounAction {

    @InvocableMethod(label='Action Label' description='What it does')
    global static List<Output> execute(List<Input> inputs) {
        Output output = new Output();
        // ... implementation ...

        return new List<Output>{ output };
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Field Label' description='Description' required=true)
        global String fieldName;

        // Note: Empty constructor required for Invocable Methods deserialization
        @SuppressWarnings('PMD.EmptyStatementBlock')
        global Input() {}
    }


    global class Output {
        @InvocableVariable(label='Result' description='Description')
        global String result;
    }
}
```

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Custom Objects | PascalCase, no underscores | `ContactSkill__c` |
| Custom Fields | camelCase, no underscores | `SkillLevel__c` |
| Triggers | Plural object name | `Contacts.trigger` |
| Test Classes | `_Test` suffix | `Pricing_Test.cls` |
| Controllers | `Ctrl` suffix | `AccountListCtrl` |
| Domain Builders (standard) | `_t` suffix | `Account_t`, `User_t` |
| Domain Builders (custom) | No suffix | `Project`, `Task` |

### Methods

No `get` prefix:

- Bad: `getAge()`, `getName()`
- Good: `age()`, `name()`

