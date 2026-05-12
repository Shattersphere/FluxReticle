# Project Doc Index

## Active Docs

- `AGENTS.md`
  - Category: instructions
  - Purpose: repo rules, commands, safety, deploy policy, verification policy, and knowledge map.
  - Status: active
  - Read when: starting repository-changing work or changing build/deploy/runtime behavior.
  - Tags: startup, deploy, verification, safety, git

- `.agent/BRIEF.md`
  - Category: brief
  - Purpose: compact current state, known-good baseline, blockers, risks, and next step.
  - Status: active
  - Read when: task depends on current project state.
  - Tags: current-state, known-good, deploy-target, blockers

- `HANDOVER.md`
  - Category: stable memory
  - Purpose: architecture, ownership map, stable decisions, validation commands, and runtime validation status.
  - Status: active
  - Read when: debugging runtime behavior, changing settings/rendering ownership, or handing off.
  - Tags: architecture, validation, settings, runtime

- `PLANS.md`
  - Category: active plan
  - Purpose: current goals, acceptance criteria, blockers, and next steps.
  - Status: active
  - Read when: work is ambiguous, risky, multi-session, or explicitly plan-driven.
  - Tags: plan, blockers, acceptance

- `README.md`
  - Category: user docs
  - Purpose: user-facing overview, features, build/deploy commands, and runtime checks.
  - Status: active
  - Read when: explaining the repo or updating user-facing usage notes.
  - Tags: overview, features, build, deploy

## Archives

- `.agent/archive/INDEX.md`
  - Category: archive index
  - Purpose: map of deep dives, history, and retired context.
  - Status: active
  - Read when: task may depend on historical/deep-dive knowledge.
  - Tags: archive, deep-dive, history

## Read Order

1. `AGENTS.md`
2. `.agent/INDEX.md`
3. `.agent/archive/INDEX.md` only when archive knowledge may matter
4. `.agent/BRIEF.md` when current state matters
5. Targeted sections of `HANDOVER.md`
6. `PLANS.md` for large, ambiguous, risky, or planned work
