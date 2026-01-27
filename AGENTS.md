# Instructions for AI Assistants

**All AI assistants working on this project should read and follow this document.**

---

## Philosophy

This codebase reflects a set of beliefs about what makes code maintainable:

1. **Readability over cleverness** - Code is read far more than it's written. Every pattern here optimizes for the reader, not the writer. The `result` variable, single returns, section comments - all serve readability.

2. **Simplicity over sophistication** - Salesforce isn't Java. We don't need complex package hierarchies or enterprise patterns. Flat folders, simple names, minimal abstraction.

3. **Explicit over implicit** - When you deviate from defaults, say why. `// Note:` comments, PMD suppression explanations, `with sharing` as default. No magic.

4. **Tests as documentation** - Test class + method name reads as a sentence describing behavior. Tests are the first place someone looks to understand what code does.

5. **Leverage existing solutions** - Don't reinvent. Use the libraries provided. They're battle-tested and consistent.

## Core Principles

These principles are non-negotiable. Many are enforced by PMD rules.

### One Return Per Method

Methods have exactly one `return` statement at the end. Use the `result` variable pattern:

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

### No Formal Comments
No JavaDoc/ApexDoc `/** */` comments. If code needs explanation, the code is unclear. Write clearer code. Write better tests.

### Tests Don't Start With "test"
Test method names describe behavior. Class + method reads as sentence:

- `Calculator_Test.multipliesTwoIntegers()` → "Calculator multiplies two integers"

### Test Method Names Describe What Is Asserted

The method name states exactly what the test verifies. The assertion should match the name - nothing more, nothing less:

- Good: `returnsOverdueTasksFirst()` with `Assert.areEqual('Overdue Task', tasks[0].Name)`
- Bad: `testPrioritization()` with multiple unrelated assertions

### Deviations Need Explanation

When you deviate from defaults (`without sharing`, `global`, PMD suppression), add a `// Note:` comment explaining why.

## Project Structure

```
force-app/
├── external-libs/                     # Pre-configured libraries (DON'T MODIFY)
│   ├── apexfarm/ApexTriggerHandler/
│   ├── beyond-the-cloud-dev/http-mock-lib/
│   ├── beyond-the-cloud-dev/soql-lib/
│   └── rsoesemann/apex-domainbuilder/
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
Assertions have no message parameter. The test method name explains what is being verified:

- Good: `Assert.areEqual('expected', actual)`
- Bad: `Assert.areEqual('expected', actual, 'Should return expected value')`

### Trigger Pattern

Uses ApexTriggerHandler library. Name triggers as plural of object:

```java
trigger Accounts on Account (before insert, after update) {
    Triggers.prepare()
        .beforeInsert()
            .bind(new ValidateAccount())
        .afterUpdate()
            .bind(new SyncToErp())
        .execute();
}
```

### Domain Builders

For test data. Standard objects use `_t` suffix, custom objects don't:

```java
// Standard objects
Account acc = (Account) new Account_t()
                    .name('Acme Corp')
                    .add(new Opportunity_t()
                                .amount(1000))
                    .persist();

// Custom objects
Project p = (Project) new Project()
                    .name('My Project')
                    .add(new Task()
                                .name('Task 1'))
                    .persist();
```

### HTTP Mocking

```java
new HttpMock()
        .post('/api/endpoint')
        .body('{"response": "data"}')
        .statusCodeOk()
        .mock();
```

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
| Custom Fields | camelCase, no underscores | `skillLevel__c` |
| Triggers | Plural object name | `Contacts.trigger` |
| Test Classes | `_Test` suffix | `Pricing_Test.cls` |
| Controllers | `Ctrl` suffix | `AccountListCtrl` |
| Domain Builders (standard) | `_t` suffix | `Account_t`, `User_t` |
| Domain Builders (custom) | No suffix | `Project`, `Task` |

### Methods

No `get` prefix:

- Bad: `getAge()`, `getName()`
- Good: `age()`, `name()`

## Access Modifiers

| Type | Access | Sharing |
|------|--------|---------|
| Regular class | `public` | `with sharing` |
| Test class | `private` | - |
| Invocable | `global` | `with sharing` |
| Controller | `public` | `with sharing` |

## Libraries

Use the pre-configured libraries in `force-app/external-libs/`:

| Library | Purpose | Source |
|---------|---------|--------|
| ApexTriggerHandler | Trigger framework | [apexfarm/ApexTriggerHandler](https://github.com/apexfarm/ApexTriggerHandler) |
| apex-domainbuilder | Test data builders | [rsoesemann/apex-domainbuilder](https://github.com/rsoesemann/apex-domainbuilder) |
| http-mock-lib | HTTP callout mocking | [beyond-the-cloud-dev/http-mock-lib](https://github.com/beyond-the-cloud-dev/http-mock-lib) |
| soql-lib | Type-safe SOQL queries | [beyond-the-cloud-dev/soql-lib](https://github.com/beyond-the-cloud-dev/soql-lib) |

## PMD Rules

A custom PMD ruleset (`pmd-ruleset.xml`) enforces many patterns. These rules are machine-checked:

- **OnlyOneReturnPerMethod** - Methods must have exactly one return statement
- **DeclareWhatYouReturnFirstAndCallItResult** - Return variable must be named `result`
- **TestsShouldNotStartWithTest** - Test method names must not start with "test"
- **UnneededUseOfThisReducesReadability** - Don't use `this.` unless required
- **CommentsOftenExcuseForBadCodeAndTests** - No formal JavaDoc/ApexDoc comments
- **PreferRealObjectsOverStaticHelpers** - Avoid classes with only static methods
- **CheckIfProperFalsePositive** - PMD suppressions need explanatory comments
- **MetadataRequiresDescription** - Custom objects/fields need descriptions
- **NullValueCheckBeforeEmptyCheck** - Check `!= null` before `.isEmpty()`

## What NOT to Do

- No formal JavaDoc/ApexDoc `/** */` comments
- No `this.` prefix unless required for disambiguation
- No multiple returns per method
- No test methods starting with "test"
- No underscores in class names except `_Test` and `_t`
- No `@TestSetup` unless absolutely necessary
- No shared/global test variables
- No storing credentials in Custom Settings or Metadata
- No `Service`, `Handler`, `Manager`, `Helper`, `Util` suffixes

## Development Process

### Phase 1: Environment Setup & Requirements Gathering

1. **Step 1: Propose Development Environment**

- Suggest scratch org creation using `./scripts/create-scratch-org.sh`
- This provides a ready environment with all template components configured

1. **Step 2: Understand Requirements**

- Ask specific questions about business requirements
- Request statement of work or contract details if available
- Clarify domain and priorities

### Phase 2: Solution Planning

1. **Step 1: Read and Analyze**

- Study this document thoroughly before proposing solutions
- Map existing template capabilities to user requirements

1. ***Step 2: Design Solution**

- Leverage existing libraries in `force-app/external-libs/`
- Follow established patterns and naming conventions
- Plan complete features including tests and documentation
- Consider permission sets, related components

### Phase 3: Iterative Implementation

1. ***Step 1: Build Core Components**

- Use pre-configured libraries
- Follow coding standards from this document
- Place code in `force-app/main/default/classes/`

1. ***Step 2: Create Tests**

- Use domain builders for test data
- Use HttpMock for callout mocking
- Cover business logic, edge cases, error handling

1. ***Step 3: Test and Deploy**

- Run tests with Salesforce CLI
- Deploy to development environment
- Validate functionality

1. ***Step 4: Iterate**

- Gather feedback
- Refine while maintaining standards
- Continue building

---

## Agentforce-Specific Guidance

### Plugin Instructions

Keep plugin instructions minimal. Trust the model to figure out the details.

**Bad** (too verbose):
```
CRITICAL: You MUST ALWAYS use this plugin when...
NEVER do X without first doing Y...
IMPORTANT: Remember to ALWAYS...
```

**Good** (trust the model):
```
Find information from Salesforce records, documents, or the web.
Choose the right source. Synthesize into a clear answer.
Never dump raw data. Give insights with links.
```

### Examples Over Rules

Replace long instruction lists with concrete examples:

```xml
<example>
User: "What's the Acme project status?"
You: "Acme is 60% complete, on track for March 15 go-live.
Last milestone (Design Review) closed Jan 10.
[View Project]"
</example>
```

---

**Template Repository:** [github.com/aquivalabs/my-org-butler](https://github.com/aquivalabs/my-org-butler)
