# Agentforce Experiment

Optimize Agentforce prompt templates by testing model and prompt variants.

Tell the skill which template to optimize and what matters (latency, quality, cost). It reads the template, proposes a matrix of models × prompt rewrites, and walks you through the experiment conversationally.

No config files to write. The conversation is the experiment design.

```
You: optimize ConsolidateMemory for latency

Skill: reads template, proposes 4 models × 3 content variants = 12 tests
       → creates variant templates in experiments/
       → deploys and runs all variants
       → presents a ranked report

You: apply #1

Skill: writes the winner into the original template and deploys
```

Uses `agentforce-eval` under the hood for Promptfoo test execution.
