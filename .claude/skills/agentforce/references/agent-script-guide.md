# Agent Script — The No-Bloat Reference

> Condensed from the official Salesforce docs, the recipe site, and the GitHub repo.
> Everything you actually need to know, nothing repeated.

---

## What It Is (In One Paragraph)

Agent Script is a YAML-like DSL for Agentforce agents. It compiles into an "Agent Graph" consumed by the Atlas Reasoning Engine. The core idea: you mix **deterministic logic** (`->` arrow blocks with `if/else`, `run`, `set`, `transition to`) with **LLM prompts** (`|` pipe blocks — natural language the LLM reasons over). That's the entire "hybrid reasoning" concept. Logic runs every time. Prompts are suggestions the LLM interprets.

source: [overview](https://developer.salesforce.com/docs/einstein/genai/guide/agent-script.html) | [intro blog](https://developer.salesforce.com/blogs/2025/10/introducing-hybrid-reasoning-with-agent-script) | [recipes overview](https://developer.salesforce.com/sample-apps/agent-script-recipes/getting-started/overview)

---

## File Structure

An `.agent` file is a sequence of top-level blocks. Order matters. Indentation: **at least 2 spaces or 1 tab** — pick one method and use it consistently throughout the script. Mixing spaces and tabs causes parsing errors. Comments: `#`.

```
config:           # Identity — required
system:           # Global messages & instructions
language:         # Locale settings (optional)
connection:       # Channel config like Enhanced Chat (optional)
variables:        # Global state — shared across all topics
start_agent:      # Entry point — routes to first topic
topic <n>:     # One or more topics — where the work happens
```

source: [blocks](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-blocks.html) | [flow of control](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-flow.html)

---

## The Two Modes: `->` vs `|`

| Syntax | Name | What Happens | Deterministic? |
|--------|------|-------------|----------------|
| `->` | **Procedure** (logic) | Code runs top-to-bottom, every time | Yes |
| `\|` | **Template** (prompt) | Text becomes part of the LLM prompt | No — LLM decides |

They combine inside `instructions:->` blocks:

```agentscript
reasoning:
   instructions:->                          # Start a procedure
      run @actions.get_order                # deterministic: always runs
         with order_id = @variables.order_id
         set @variables.status = @outputs.status
      if @variables.status == "shipped":    # deterministic: always evaluates
         | Your order has shipped! Tracking: {!@variables.tracking_number}
           Ask if they need anything else.  # prompt: LLM uses this text
      else:
         | The order is still processing.
           Reassure the customer.           # prompt: LLM uses this text
```

**Rule of thumb:** After `->`, you write code. After `|`, you write English (which becomes the LLM prompt). You can nest `|` inside `->` to mix logic with prompts.

source: [reasoning instructions](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-instructions.html) | [conditional expressions](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-expressions.html)

---

## Execution Model

**All `->` logic resolves first, then the resulting `|` text is sent to the LLM as a single prompt.** Agentforce processes reasoning instructions line by line, top to bottom — running actions, evaluating conditionals, and collecting prompt text.

This means the LLM cannot influence earlier deterministic branching. By the time the LLM sees the prompt, all `if/else` decisions have already been made and all `run` actions have already executed.

source: [flow of control](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-flow.html)

---

## Blocks In Detail

### config (required)

```agentscript
config:
   agent_name: "Order_Support"        # snake_case, max 80 chars
   agent_label: "Order Support Agent"  # Display name
   description: "Handles order inquiries"
```

source: [blocks](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-blocks.html)

### system

```agentscript
system:
   messages:
      welcome: "Hi! How can I help?"
      error: "Something went wrong."
   instructions: "You are a helpful support agent. Be concise."
```

`instructions` here is global — applies to ALL topics. Topic-level instructions override/extend.

source: [blocks](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-blocks.html)

### variables

```agentscript
variables:
   # Regular variables
   order_id: mutable string = ""                        # Mutable = agent can change it
   is_member: boolean = False                           # Immutable = never changes
   retry_count: mutable number = 0                      # number = int or float
   preferences: mutable object = {"theme": "dark"}      # JSON object
   tags: mutable list[string] = ["new"]                 # Typed lists

   # Linked variables (value comes from action output, no default allowed)
   current_temp: linked number                          # Set by action output only
```

**Types:** `string`, `number`, `boolean`, `object`, `date`, `id`, `list[<type>]`

**Boolean literals are case-sensitive:** `True` and `False` (capitalized). `true`/`false` will not work.

**Access:**
- In logic: `@variables.order_id`
- In templates/prompts: `{!@variables.order_id}`
- Setting: `set @variables.order_id = "12345"`

source: [variables](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-variables.html)

### start_agent

The entry point. **Runs on every customer utterance** — not just the first one. After any topic completes and the customer sends a new message, execution returns here. This means routing logic repeats unless you guard it (e.g., check a variable to skip re-routing if the user is already in a topic).

There is a built-in global turn counter `num_turns` that Agentforce increments automatically on each pass through a topic. You can use it in conditions:

```agentscript
start_agent topic_selector:
   description: "Routes user to the right topic"
   reasoning:
      instructions:|
         Select the best matching tool for the user's message.
      actions:
         go_orders: @utils.transition to @topic.order_management
            description: "User wants help with orders"
         go_account: @utils.transition to @topic.account_help
            description: "User wants account help"
```

source: [blocks — start_agent](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-blocks.html#start-agent-block) | [flow of control](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-flow.html)

### topic

Where all the real work happens.

```agentscript
topic order_management:
   description: "Handles order lookups and returns"

   actions:                          # Define callable actions
      get_order:
         target: flow://Get_Order_Details
         inputs:
            order_id: string
         outputs:
            status: string
            tracking: string

   reasoning:
      instructions:->                # Procedural logic + prompts
         | Help the customer with their order.
         run @actions.get_order
            with order_id = @variables.order_id
            set @variables.order_status = @outputs.status

      actions:                       # Tools the LLM can CHOOSE to use
         lookup_tool: @actions.get_order
            description: "Look up order details"
            with order_id = ...      # ... = LLM fills this (slot-filling)
            set @variables.order_status = @outputs.status
```

source: [blocks — topic](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-blocks.html#topic-blocks) | [multi-topic recipe](https://developer.salesforce.com/sample-apps/agent-script-recipes/architectural-patterns/multi-topic-navigation)

---

## Actions — Three Ways to Run Them

### 1. `run` in logic (100% deterministic — always executes)

```agentscript
instructions:->
   run @actions.get_order
      with order_id = @variables.order_id
      set @variables.status = @outputs.status
```

### 2. `{!@actions.name}` in a prompt (suggestion — LLM decides)

```agentscript
instructions:->
   | Use {!@actions.get_order} to look up the customer's order
     when they provide an order number.
```

### 3. Reasoning action / tool (LLM picks from a toolbox)

```agentscript
reasoning:
   actions:
      order_lookup: @actions.get_order
         description: "Fetches order details by ID"
         with order_id = ...
         set @variables.status = @outputs.status
         available when @variables.order_id != ""
```

source: [actions](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-actions.html) | [tools](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-tools.html)

---

## Action Definition

```agentscript
actions:
   <n>:
      target: flow://Flow_Api_Name       # or apex://ClassName or prompt://TemplateName
      description: "What this does"       # Helps LLM pick the right action
      label: "Friendly Name"             # Optional UI label
      require_user_confirmation: True     # Optional — ask before running
      inputs:
         param_name: <type>              # string, number, boolean, object, date, id, list[type]
      outputs:
         result_field:
            type: string
            description: "What this returns"
            filter_from_agent: False      # True = hide from LLM context
```

**Targets:** `flow://`, `apex://`, `prompt://`

source: [actions](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-actions.html)

---

## Input Binding — Three Flavors

```agentscript
with order_id = @variables.order_id    # Bound — explicit value
with order_id = "FIXED_VALUE"          # Fixed — hardcoded
with order_id = ...                    # Slot-fill — LLM asks user & fills it
```

**Limitation:** You can use slot-filling (`...`) for top-level action inputs, but **not for chained action inputs**.

source: [actions](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-actions.html) | [variables — slot filling](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-variables.html)

---

## Topic Navigation — Two Mechanisms

| Mechanism | Syntax | Returns to caller? |
|-----------|--------|-------------------|
| **Transition** | `transition to @topic.name` or `@utils.transition to @topic.name` | No — one-way |
| **Delegation** | `@topic.name` (direct reference in reasoning actions) | Yes — like a function call |

```agentscript
# One-way transition (in logic)
instructions:->
   if @variables.needs_specialist:
      transition to @topic.specialist

# One-way transition (as LLM tool)
reasoning:
   actions:
      go_help: @utils.transition to @topic.account_help
         description: "Navigate to account help"

# Delegation — returns after topic completes (as LLM tool)
reasoning:
   actions:
      consult_specialist: @topic.specialist_topic
         description: "Ask the specialist, then come back"
```

source: [utils](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-utils.html) | [tools](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-tools.html)

---

## Conditionals and Filters

### if / else

Agent Script supports `if` and `else`, but **does not support `else if`**. To handle multiple conditions, use nested `if`/`else` blocks:

```agentscript
instructions:->
   if @variables.is_member == True:
      | Welcome back, valued member! {!@variables.member_name}
   else:
      if @variables.visit_count > 5:
         | Welcome back! You've visited {!@variables.visit_count} times.
      else:
         | Welcome! Let me know how I can help.
```

### Comparison and logical operators

**Comparison:** `==`, `!=`, `>`, `<`, `>=`, `<=`
**Identity:** `is None`, `is not None`
**Logical:** `and`, `or`, `not`
**Arithmetic:** `+`, `-` (only addition and subtraction are documented; `*` and `/` are not listed in the official operator reference)

### None checks

Use `is None` and `is not None` to check for empty/unset values:

```agentscript
instructions:->
   if @variables.customer_email is None:
      | Please ask the customer for their email address.
   else:
      run @actions.lookup_customer
         with email = @variables.customer_email
         set @variables.customer_id = @outputs.id
```

### `available when` — Guard clauses on tools

Control when tools are visible to the LLM. If the condition is false, the LLM doesn't even see the tool:

```agentscript
reasoning:
   actions:
      submit_order: @actions.place_order
         description: "Submit the customer's order"
         available when @variables.cart_total > 0 and @variables.address != ""

      cancel_order: @actions.cancel_order
         description: "Cancel the order"
         available when @variables.order_status == "processing"

      apply_discount: @actions.apply_discount
         description: "Apply member discount"
         available when @variables.is_member == True and @variables.discount_applied is not None
```

### `filter_from_agent` — Hiding outputs from the LLM

By default, the agent remembers all action outputs for the entire session and can use them to reason and answer questions. Set `filter_from_agent: True` on an output to hide it from the LLM's context while still making it available for deterministic logic via `@variables`:

```agentscript
actions:
   get_account:
      target: flow://Get_Account_Details
      inputs:
         account_id: string
      outputs:
         account_name:
            type: string
            description: "The account display name"
         internal_score:
            type: number
            description: "Internal risk score"
            filter_from_agent: True     # LLM won't see this, but logic can use it
```

This is useful when you need a value for branching logic but don't want the LLM to mention or reason about it in conversation. **Use this for sensitive outputs** — internal scores, PII, pricing tiers, or any data the agent should act on but never surface to the user.

source: [conditional expressions](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-expressions.html) | [operators](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-operators.html) | [tools — available when](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-tools.html) | [actions — filter_from_agent](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-actions.html)

---

## Template Expressions `{!...}`

Inside `|` blocks, `{!...}` evaluates expressions:

```agentscript
| Hello {!@variables.name}                              # Variable interpolation
| Your total is {!@variables.subtotal + @variables.tax}  # Arithmetic
| Use {!@actions.get_order} to look up orders           # Action reference (hint to LLM)
```

source: [reasoning instructions](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-instructions.html) | [template expressions recipe](https://developer.salesforce.com/sample-apps/agent-script-recipes/language-essentials/template-expressions)

---

## Utils

```agentscript
@utils.transition to @topic.<n>       # One-way topic switch
@utils.set_variable                       # LLM sets a variable via slot-fill
   with variable = @variables.<n>
   with value = ...                       # ... = LLM figures it out
   description: "Capture the customer's name"
@utils.escalate                           # Hand off to human agent
```

`@utils.escalate` requires an active Omni-Channel connection defined in a `connection` block:

```agentscript
connection:
   messaging:
      outbound_route_type: queue           # or skill
      outbound_route_name: "Support_Queue"
      escalation_message: "Transferring you to a human agent."
      adaptive_response_allowed: True
```

source: [utils](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-utils.html)

---

## Lifecycle Hooks

```agentscript
topic my_topic:
   before_reasoning:->                   # Runs BEFORE each reasoning turn
      run @actions.refresh_data
         set @variables.data = @outputs.fresh_data

   reasoning:
      instructions:->
         | Use the refreshed data: {!@variables.data}

   after_reasoning:->                    # Runs AFTER each reasoning turn
      set @variables.turn_count = @variables.turn_count + 1
```

**Restrictions:** `before_reasoning` and `after_reasoning` can contain logic, actions, transitions, and directives, but **cannot contain `|` (pipe/template) blocks**. They are purely deterministic.

**Transitions from hooks:** When transitioning from `after_reasoning`, use `transition to` rather than `@utils.transition to`:

```agentscript
after_reasoning:->
   if @variables.num_turns > 5:
      transition to @topic.wrap_up
```

If a topic transitions to a new topic partway through execution, the original topic's `after_reasoning` block is not run.

source: [before/after reasoning](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-before-after-reasoning.html) | [flow of control](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-flow.html)

---

## Guard Clauses (`available when`)

Control when tools are visible to the LLM:

```agentscript
reasoning:
   actions:
      submit_order: @actions.place_order
         description: "Submit the customer's order"
         available when @variables.cart_total > 0 and @variables.address != ""
```

source: [tools](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-tools.html)

---

## System Instruction Overrides (Per-Topic Persona)

```agentscript
topic tech_support:
   description: "Technical troubleshooting"
   system:
      instructions: "You are a senior technical support engineer. Be precise and methodical."
   reasoning:
      instructions:->
         | Diagnose the customer's issue step by step.
```

This **overrides** the global `system.instructions` for this topic only.

source: [blocks — topic](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-blocks.html#topic-blocks)

---

## Language / Locale

```agentscript
language:
   default_locale: en_US
   additional_locales: [de_DE, fr_FR]
```

source: [blocks](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-blocks.html)

---

## Migrating from Old Agentforce to Agent Script

If you're coming from the Agentforce Builder UI (Topics + Actions + Instructions configured via point-and-click), here's how each concept maps to Agent Script.

### Topics -> `topic` blocks

In the old builder, you created topics in the UI with a classification description, scope, and instructions as separate text fields. In Agent Script, all of that becomes a single `topic` block:

| Builder UI field | Agent Script equivalent |
|-----------------|----------------------|
| Topic name | `topic my_topic_name:` |
| Classification description | `description: "..."` on the topic |
| Scope / "what this topic can do" | Covered by `reasoning.instructions` and available `actions` |
| Instructions (numbered text boxes) | `reasoning: instructions:` — either `->` for logic or `\|` for prompts |

The key difference: in the builder, instructions were flat text boxes the LLM interpreted entirely. In Agent Script, you can now make parts deterministic with `->`. You don't have to — `instructions:|` still works exactly like the old text-box instructions — but now you *can* enforce execution order and logic.

### Standard Topics and Standard Actions

The old builder provides standard (pre-built) topics and standard actions like "Query Records", "Summarize Records", and "Identify Record by Name." These come out of the box and can be assigned to agents in the builder UI.

I don't have confirmed documentation on how standard topics and standard actions are referenced or integrated within Agent Script `.agent` files specifically. The official docs focus on custom actions with explicit `target:` definitions (`flow://`, `apex://`, `prompt://`). If you need to use standard actions alongside Agent Script, check the current Agentforce Builder documentation for the latest on how they interact — this may have changed since the beta.

source: [customize agents without agent script](https://developer.salesforce.com/docs/einstein/genai/guide/agent-dx-modify.html)

### Custom Actions (Flow / Apex / Prompt Template) -> `actions:` block

In the old builder, you created a custom action by selecting a flow, Apex class, or prompt template, then mapping inputs and outputs in the UI. In Agent Script:

```agentscript
topic order_management:
   actions:
      get_order:                               # Action name
         target: flow://Get_Order_Details      # flow://, apex://, or prompt://
         inputs:
            order_id: string
         outputs:
            status: string
            tracking_number: string
```

The target string replaces the point-and-click selection. Input/output mapping that was done via UI fields is now explicit YAML.

### "Collect from user" -> Slot-fill (`...`)

In the builder, you could mark an action input as "Collect from user" so the agent would ask for it. In Agent Script, this is the `...` (slot-fill) operator:

```agentscript
reasoning:
   actions:
      lookup: @actions.get_order
         description: "Look up an order"
         with order_id = ...              # Agent asks the user for this
```

For inputs you want to bind explicitly (what was "Use variable" or "Use constant" in the builder), use `with param = @variables.x` or `with param = "fixed_value"`.

### "Show in conversation" / "Hide" -> `filter_from_agent`

The builder let you toggle whether an action output was visible to the agent. In Agent Script, this becomes `filter_from_agent: True` on the output definition to hide it from the LLM's context while still making it available for deterministic logic.

### Topic Instructions -> `reasoning: instructions:` (with new superpowers)

The old builder gave you numbered instruction text boxes — all pure LLM prompt text. Agent Script gives you the same capability via `instructions:|`, but also lets you use `instructions:->` for deterministic logic. Here's the progression:

**Old way (still works — pure prompt text):**
```agentscript
reasoning:
   instructions:|
      Help the customer find their order.
      Ask for their order number if they haven't provided it.
      Look up the order and share the status.
```

**New way (mix logic with prompts for guaranteed execution):**
```agentscript
reasoning:
   instructions:->
      if @variables.order_id is None:
         | Ask the customer for their order number.
      else:
         run @actions.get_order
            with order_id = @variables.order_id
            set @variables.status = @outputs.status
         | The order status is {!@variables.status}. Share this with the customer.
```

The `->` version guarantees the action runs and the conditional evaluates. The `|` version is a suggestion the LLM interprets. Mix them as needed.

### Require Confirmation -> `require_user_confirmation: True`

The builder had a checkbox for this. In Agent Script, it's a property on the action definition.

### Guard Conditions -> `available when`

In the builder, you could conditionally show/hide actions using filter criteria. In Agent Script, this becomes `available when` on a reasoning action:

```agentscript
reasoning:
   actions:
      cancel_order: @actions.cancel_order
         description: "Cancel the order"
         available when @variables.order_status == "processing"
```

### What's New (No Builder Equivalent)

These capabilities didn't exist in the old Agentforce builder:

- **`before_reasoning` / `after_reasoning` hooks** — Run logic before or after every LLM turn (refresh data, increment counters, audit logging)
- **`linked` variables** — Variables whose value is always sourced from an action output, never set manually
- **Per-topic `system.instructions`** — Override the agent's persona per topic
- **Delegation (`@topic.x`)** — Call another topic like a function and return, instead of only transitioning one-way
- **Conditional topic transitions in logic** — `if/else` branching to deterministically decide which topic to enter
- **Template expressions with arithmetic** — `{!@variables.subtotal + @variables.tax}` computed at runtime

source: [examples](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-example.html) | [recipes](https://developer.salesforce.com/sample-apps/agent-script-recipes/getting-started/overview) | [github](https://github.com/trailheadapps/agent-script-recipes)

---

## Naming Rules (One Place, Not Five)

- Letters, numbers, underscores only
- Must start with a letter
- Cannot end with underscore
- No consecutive underscores (`__`)
- Max 80 characters
- Convention: `snake_case`

source: [variables](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-ref-variables.html)

## Syntax Cheat Sheet

| Symbol | Meaning |
|--------|---------|
| `->` | Start a procedure block (deterministic logic) |
| `\|` | Start a template/prompt string (for the LLM) |
| `@variables.x` | Reference a variable |
| `{!@variables.x}` | Interpolate a variable inside `\|` blocks |
| `@actions.x` | Reference an action |
| `@topic.x` | Reference a topic (delegation — returns) |
| `@utils.transition to` | One-way topic switch (no return) |
| `@utils.set_variable` | LLM slot-fills a variable |
| `@utils.escalate` | Hand off to human agent |
| `@outputs.x` | Reference action output (after `run` or in `set`) |
| `run` | Execute an action deterministically |
| `set` | Store a value in a variable |
| `with` | Bind an input parameter |
| `...` | LLM slot-fill (asks user and fills value) |
| `if / else` | Conditional branching (no `else if` — use nested `if`/`else`) |
| `is None / is not None` | Check for empty/unset values |
| `True / False` | Boolean literals (case-sensitive, must be capitalized) |
| `num_turns` | Built-in global turn counter, auto-incremented by Agentforce |
| `transition to` | One-way topic switch (in logic) |
| `available when` | Guard clause for tools |
| `filter_from_agent` | Hide output from LLM context |
| `#` | Comment |

---

*Sources: [official docs](https://developer.salesforce.com/docs/einstein/genai/guide/agent-script.html) | [reference index](https://developer.salesforce.com/docs/einstein/genai/guide/ascript-reference.html) | [recipe site](https://developer.salesforce.com/sample-apps/agent-script-recipes/getting-started/overview) | [github recipes](https://github.com/trailheadapps/agent-script-recipes) | [intro blog](https://developer.salesforce.com/blogs/2025/10/introducing-hybrid-reasoning-with-agent-script) | [recipes blog](https://developer.salesforce.com/blogs/2025/12/master-hybrid-reasoning-with-the-new-agent-script-recipes-sample-app)*
