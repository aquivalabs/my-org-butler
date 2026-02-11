# Agent Script — The No-Bloat Reference

> Condensed from the official Salesforce docs, the recipe site, and the GitHub repo.
> Everything you actually need to know, nothing repeated.

---

## What It Is (In One Paragraph)

Agent Script is a YAML-like DSL for Agentforce agents. It compiles into an "Agent Graph" consumed by the Atlas Reasoning Engine. The core idea: you mix **deterministic logic** (`->` arrow blocks with `if/else`, `run`, `set`, `transition to`) with **LLM prompts** (`|` pipe blocks — natural language the LLM reasons over). That's the entire "hybrid reasoning" concept. Logic runs every time. Prompts are suggestions the LLM interprets.

---

## File Structure

An `.agent` file is a sequence of top-level blocks. Order matters. Indentation: **3 spaces** (Python-style). Comments: `#`.

```
config:           # Identity — required
system:           # Global messages & instructions
language:         # Locale settings (optional)
connection:       # Channel config like Enhanced Chat (optional)
variables:        # Global state — shared across all topics
start_agent:      # Entry point — routes to first topic
topic <name>:     # One or more topics — where the work happens
```

That's it. Every recipe and every production agent is just a composition of these blocks.

---

## The Two Modes: `->` vs `|`

This is **the single most important concept** and the docs bury it in 15 pages. Here it is:

| Syntax | Name | What Happens | Deterministic? |
|--------|------|-------------|----------------|
| `->` | **Procedure** (logic) | Code runs top-to-bottom, every time | ✅ Yes |
| `\|` | **Template** (prompt) | Text becomes part of the LLM prompt | ❌ No — LLM decides |

They combine inside `instructions:->` blocks:

```agentscript
reasoning:
   instructions:->                          # Start a procedure
      run @actions.get_order                # ← deterministic: always runs
         with order_id = @variables.order_id
         set @variables.status = @outputs.status
      if @variables.status == "shipped":    # ← deterministic: always evaluates
         | Your order has shipped! Tracking: {!@variables.tracking_number}
           Ask if they need anything else.  # ← prompt: LLM uses this text
      else:
         | The order is still processing.
           Reassure the customer.           # ← prompt: LLM uses this text
```

**Rule of thumb:** After `->`, you write code. After `|`, you write English (which becomes the LLM prompt). You can nest `|` inside `->` to mix logic with prompts.

---

## Blocks In Detail

### config (required)

```agentscript
config:
   agent_name: "Order_Support"        # snake_case, max 80 chars
   agent_label: "Order Support Agent"  # Display name
   description: "Handles order inquiries"
```

### system

```agentscript
system:
   messages:
      welcome: "Hi! How can I help?"
      error: "Something went wrong."
   instructions: "You are a helpful support agent. Be concise."
```

`instructions` here is global — applies to ALL topics. Topic-level instructions override/extend.

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

**Access:**
- In logic: `@variables.order_id`
- In templates/prompts: `{!@variables.order_id}`
- Setting: `set @variables.order_id = "12345"`

### start_agent

The entry point. Routes to the first topic.

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

---

## Actions — Three Ways to Run Them

This is where the docs get really confusing. There are exactly **three** ways to invoke an action, each with a different level of determinism:

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

**Summary:** `run` = always. `{!ref}` in `|` = maybe. `reasoning.actions` = LLM's choice.

---

## Action Definition

```agentscript
actions:
   <name>:
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

---

## Input Binding — Three Flavors

```agentscript
with order_id = @variables.order_id    # Bound — explicit value
with order_id = "FIXED_VALUE"          # Fixed — hardcoded
with order_id = ...                    # Slot-fill — LLM asks user & fills it
```

---

## Topic Navigation — Two Mechanisms

| Mechanism | Syntax | Returns to caller? |
|-----------|--------|-------------------|
| **Transition** | `transition to @topic.name` or `@utils.transition to @topic.name` | ❌ No — one-way |
| **Delegation** | `@topic.name` (direct reference in reasoning actions) | ✅ Yes — like a function call |

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

---

## Conditionals

```agentscript
instructions:->
   if @variables.is_member == True:
      | Welcome back, valued member! {!@variables.member_name}
   else if @variables.visit_count > 5:
      | Welcome back! You've visited {!@variables.visit_count} times.
   else:
      | Welcome! Let me know how I can help.
```

**Operators:** `==`, `!=`, `>`, `<`, `>=`, `<=`, `and`, `or`, `not`
**Arithmetic:** `+`, `-`, `*`, `/`

---

## Template Expressions `{!...}`

Inside `|` blocks, `{!...}` evaluates expressions:

```agentscript
| Hello {!@variables.name}                              # Variable interpolation
| Your total is {!@variables.price * @variables.qty}    # Arithmetic
| Use {!@actions.get_order} to look up orders           # Action reference (hint to LLM)
```

---

## Utils

```agentscript
@utils.transition to @topic.<name>       # One-way topic switch
@utils.set_variable                       # LLM sets a variable via slot-fill
   with variable = @variables.<name>
   with value = ...                       # ... = LLM figures it out
   description: "Capture the customer's name"
@utils.escalate                           # Hand off to human agent
```

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

---

## Language / Locale

```agentscript
language:
   default_locale: en_US
   additional_locales: [de_DE, fr_FR]
```

---

## Complete Minimal Agent

```agentscript
config:
   agent_name: "Hello_World"
   agent_label: "Hello World"
   description: "Simplest possible agent"

system:
   messages:
      welcome: "Hello! How can I help?"
      error: "Something went wrong."
   instructions: "You are a friendly assistant."

start_agent topic_selector:
   description: "Route to greeting"
   reasoning:
      actions:
         begin: @utils.transition to @topic.greeting
            description: "Start greeting"

topic greeting:
   description: "Greets the user"
   reasoning:
      instructions:->
         | Greet the user warmly and ask how you can help.
```

---

## Complete Real-World Pattern

```agentscript
config:
   agent_name: "Order_Agent"
   agent_label: "Order Support"
   description: "Handles order inquiries with authentication"

variables:
   customer_email: mutable string = ""
   is_verified: mutable boolean = False
   order_status: mutable string = ""

system:
   messages:
      welcome: "Hi! I can help with your orders."
      error: "Sorry, something went wrong. Let me try again."
   instructions: "Be helpful, concise, and professional."

start_agent router:
   description: "Route customer to the right topic"
   reasoning:
      actions:
         go_verify: @utils.transition to @topic.verify_customer
            description: "Customer needs to verify identity"
         go_orders: @utils.transition to @topic.order_lookup
            description: "Customer wants order info"
            available when @variables.is_verified == True

topic verify_customer:
   description: "Verify customer identity"

   actions:
      send_code:
         target: flow://Send_Verification_Code
         inputs:
            email: string
         outputs:
            success: boolean

   reasoning:
      instructions:->
         if @variables.is_verified == True:
            transition to @topic.order_lookup
         | Ask the customer for their email to verify their identity.
      actions:
         capture_email: @utils.set_variable
            with variable = @variables.customer_email
            with value = ...
            description: "Capture the customer's email address"
         verify: @actions.send_code
            description: "Send verification code"
            with email = @variables.customer_email
            set @variables.is_verified = @outputs.success

topic order_lookup:
   description: "Look up and report on order status"

   actions:
      get_order:
         target: apex://OrderLookupAction
         inputs:
            email: string
         outputs:
            status: string
            tracking_number: string
            delivery_date: date

   reasoning:
      instructions:->
         run @actions.get_order
            with email = @variables.customer_email
            set @variables.order_status = @outputs.status
         if @variables.order_status == "shipped":
            | Great news! Your order has shipped.
              Tracking number: {!@outputs.tracking_number}
              Expected delivery: {!@outputs.delivery_date}
         else if @variables.order_status == "processing":
            | Your order is being processed. It should ship within 2 business days.
         else:
            | I couldn't find an active order. Let me help you figure this out.
```

---

## Naming Rules (One Place, Not Five)

- Letters, numbers, underscores only
- Must start with a letter
- Cannot end with underscore
- No consecutive underscores (`__`)
- Max 80 characters
- Convention: `snake_case`

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
| `@utils.escalate` | Hand off to human |
| `@outputs.x` | Reference action output (after `run` or in `set`) |
| `run` | Execute an action deterministically |
| `set` | Store a value in a variable |
| `with` | Bind an input parameter |
| `...` | LLM slot-fill (asks user and fills value) |
| `if / else if / else` | Conditional branching |
| `transition to` | One-way topic switch (in logic) |
| `available when` | Guard clause for tools |
| `#` | Comment |

---

*Sources: [Official Docs](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html) · [Recipe Site](https://developer.salesforce.com/sample-apps/agent-script-recipes/getting-started/overview) · [GitHub Recipes](https://github.com/trailheadapps/agent-script-recipes) · [Intro Blog Post](https://developer.salesforce.com/blogs/2025/10/introducing-hybrid-reasoning-with-agent-script)*
