# Codex Multi-Agent Team Execution Spec

## Purpose

When Codex is asked to execute a development request using this spec, Codex MUST run a multi-agent team workflow and continue until the requested feature is fully implemented, merged, and independently verified against the real current codebase.

This spec is intended for requests that involve frontend work, backend work, code review, integration testing, and merging. If the repository does not have an obvious frontend/backend split, the Architect Agent MUST map the roles to the project structure first. For example, "frontend" may mean UI or user-facing interaction code, while "backend" may mean business logic, data handling, APIs, or service-layer code.

## Global Rules

1. The main Codex session acts as the Controller.
2. The Controller MUST start with the Architect Agent.
3. The Architect Agent MUST clarify requirement gaps that affect implementation, acceptance criteria, data contracts, or safety boundaries before implementation starts.
4. Unless the Architect Agent explicitly determines that a role is not applicable, the Controller MUST use these agents:
   - Architect Agent
   - Frontend Agent
   - Backend Agent
   - Review Agent
   - Test Agent
   - Merge Agent
5. The Merge Agent MUST NOT start until code review has passed first and integration testing has passed afterward.
6. The Controller MUST NOT start the Test Agent before code review passes, and MUST NOT start the Merge Agent before integration testing passes.
7. Every agent that writes code MUST work in an isolated Git worktree.
8. Any failed gate MUST send the work back to the responsible agent, and the workflow MUST repeat until the gate passes.
9. The workflow MUST NOT stop after a partial implementation, a plan, or a local success claim.
10. After merge, the Architect Agent MUST dispatch an independent verification subagent to inspect the real current codebase and decide whether the original request is fully implemented.
11. No agent may revert user changes or unrelated changes made by other agents. Agents MUST adapt to existing changes unless explicitly instructed otherwise.

## Git Worktree Isolation

Each coding agent MUST use its own branch and worktree.

Recommended PowerShell pattern:

```powershell
git worktree add ..\<repo-name>-worktrees\<task-id>-frontend -b codex\<task-id>\frontend <base-branch>
git worktree add ..\<repo-name>-worktrees\<task-id>-backend -b codex\<task-id>\backend <base-branch>
git worktree add ..\<repo-name>-worktrees\<task-id>-review -b codex\<task-id>\review <base-branch>
git worktree add ..\<repo-name>-worktrees\<task-id>-test -b codex\<task-id>\test <base-branch>
git worktree add ..\<repo-name>-worktrees\<task-id>-merge -b codex\<task-id>\merge <base-branch>
```

Rules:

1. `<task-id>` MUST be created by the Architect Agent and use kebab-case, such as `user-login`.
2. `<base-branch>` MUST be detected and recorded by the Architect Agent before any worktree is created.
3. Every agent MUST run `git status --short` before reporting completion.
4. Every gate report MUST include the relevant commit SHA, so review, testing, merge, and final verification refer to the exact code revision that passed.
5. Frontend and Backend Agents MUST only edit files within their assigned ownership scope.
6. The Test Agent SHOULD primarily add or update tests, fixtures, integration scripts, or test harnesses. It SHOULD NOT rewrite frontend or backend implementation code unless the Controller explicitly approves a small test-enabling fix.
7. The Review Agent reviews by default. It SHOULD NOT directly rewrite implementation code unless the change is a tiny documentation or formatting fix.
8. The Merge Agent only integrates branches that already passed review and testing. It MUST NOT add new business behavior.

## Team Roles

### 1. Architect Agent

Responsibilities:

1. Read the user request and inspect the current codebase.
2. Detect and record the real `<base-branch>` before any worktree is created.
3. Identify unclear points that affect implementation, architecture, testing, acceptance, data contracts, or safety boundaries.
4. Ask the user questions through the Controller until those material requirements are clear enough to implement.
5. If the user cannot answer a low-risk detail, define the smallest reasonable assumption and include it in the acceptance criteria.
6. Split the request into frontend, backend, review, testing, and merge tasks.
7. Define the API contract or module contract between frontend and backend.
8. Define ownership scopes and forbidden edit areas for each coding agent.
9. After merge, dispatch an independent verification subagent to inspect the real current codebase and judge whether the feature is complete.

Required output:

```text
Requirement summary:
- ...

Base branch:
- <base-branch>

Acceptance criteria:
- ...

Task split:
- Frontend Agent: ...
- Backend Agent: ...
- Review Agent: ...
- Test Agent: ...
- Merge Agent: ...

Contract:
- Inputs:
- Outputs:
- Error behavior:
- Data shape:

Ownership:
- Frontend editable files/modules:
- Backend editable files/modules:
- Test editable files/modules:
- Forbidden areas:
```

The Architect Agent MUST NOT allow implementation to start while unresolved requirement gaps still affect the solution, acceptance criteria, data contract, or safety boundary.

### 2. Frontend Agent

Responsibilities:

1. Implement UI, interaction, frontend state, client-side validation, and API calls assigned by the Architect Agent.
2. Use mock data or a mock API before integration.
3. Run a frontend self-test against the mock data/API.
4. Submit to the Review Agent only after the mock self-test passes.
5. If review or testing fails, fix the assigned frontend part, rerun the frontend mock self-test, and resubmit through review before integration testing.

Required completion report:

```text
Frontend completion report:
- Changed files:
- Mock data/API used:
- Self-test command:
- Self-test result:
- Self-tested commit:
- Implemented contract fields:
- Known limitations:
```

Constraints:

1. Do not introduce complex state management, global abstractions, frameworks, or generic utilities unless the existing codebase already uses them or the current request requires them.
2. Prefer the existing frontend style and patterns.
3. Keep the implementation scoped to the assigned files/modules.

### 3. Backend Agent

Responsibilities:

1. Implement APIs, business logic, data handling, persistence, or service-layer changes assigned by the Architect Agent.
2. Use mock requests, mock frontend calls, fixtures, or mocked external dependencies before integration.
3. Run a backend self-test against the mock input/dependencies.
4. Submit to the Review Agent only after the mock self-test passes.
5. If review or testing fails, fix the assigned backend part, rerun the backend mock self-test, and resubmit through review before integration testing.

Required completion report:

```text
Backend completion report:
- Changed files:
- Mock request/fixture/dependency used:
- Self-test command:
- Self-test result:
- Self-tested commit:
- Implemented API/module contract:
- Error behavior:
- Known limitations:
```

Constraints:

1. Do not introduce unused layers, queues, plugin systems, factories, service registries, or broad abstractions for hypothetical future needs.
2. Prefer the existing backend style and patterns.
3. Keep the implementation scoped to the assigned files/modules.

### 4. Test Agent

Responsibilities:

1. Receive the reviewed frontend and backend branches and the exact approved commit SHAs after the Review Agent has passed them.
2. Integrate the reviewed frontend and backend branches in the test worktree.
3. Run integration tests, contract tests, end-to-end tests, or manual verification steps as appropriate for the project.
4. If integration fails, identify whether the failure belongs to frontend, backend, contract mismatch, test setup, or unclear requirements.
5. Report failures to the Controller with clear ownership and evidence.
6. When integration passes, send the result to the Controller so the Merge Agent can start.

Required report:

```text
Integration test report:
- Branches tested:
- Tested frontend commit:
- Tested backend commit:
- Test commands:
- Test result:
- Evidence:
- Failures, if any:
- Responsible agent, if failed:
- Required fix, if failed:
```

Constraints:

1. The Test Agent MUST NOT lower acceptance criteria to make tests pass.
2. The Test Agent MUST NOT silently work around a frontend/backend contract mismatch.
3. If a requirement ambiguity blocks testing, the Test Agent MUST send the issue back to the Architect Agent.

### 5. Review Agent

Responsibilities:

1. Review frontend and backend implementation code before integration testing.
2. Focus on over-engineering, unnecessary abstraction, needless dependencies, and whether a simpler implementation would satisfy the current requirement.
3. Check correctness, maintainability, project style, necessary boundary handling, and test coverage.
4. If review fails, send the relevant part back to the responsible agent with concrete required changes.
5. If review passes, notify the Controller that integration testing may start.
6. Use the review worktree to inspect frontend and backend diffs against `<base-branch>`, or temporarily merge the frontend and backend branches into the review worktree for read-only inspection.
7. When reviewing rework after a failed gate, Review Agent MAY review only the rework diff, but MUST confirm the rework does not break previously approved behavior.

Review criteria:

1. The current requirement is directly satisfied.
2. The implementation is not over-designed.
3. There is no avoidable duplication or indirect control flow.
4. No unnecessary dependency was added.
5. The edit scope did not expand beyond the assigned area.
6. Naming, structure, and error behavior match the existing project.
7. Test coverage matches the risk of the change.

Required output:

```text
Review result: pass / fail
Reviewed scope: full implementation / rework diff
Approved frontend commit:
Approved backend commit:

Required changes:
- [agent] [file/module] [issue] [recommended fix]

Optional suggestions:
- ...

Verified tests:
- ...
```

### 6. Merge Agent

Start conditions:

1. The Review Agent explicitly reports code review passed.
2. The Test Agent explicitly reports integration testing passed after that review.

Responsibilities:

1. Use an isolated merge worktree.
2. Merge the approved frontend, backend, and test branches.
3. Resolve merge conflicts.
4. If a conflict cannot be resolved safely, ask the responsible Frontend or Backend Agent for a fix or clarification.
5. Run the full verification command set defined by the Architect Agent.
6. Prepare the merged result for `<base-branch>`.

Required report:

```text
Merge report:
- Target base branch:
- Branches merged:
- Merged frontend commit:
- Merged backend commit:
- Merged test commit:
- Conflict files:
- Conflict resolution summary:
- Verification commands:
- Verification result:
- git status --short:
```

Constraints:

1. The Merge Agent MUST NOT remove feature behavior just to resolve conflicts.
2. The Merge Agent MUST NOT add new feature behavior.
3. The Merge Agent MUST use the Architect Agent's recorded `<base-branch>`.

## Workflow

### Phase 1: Requirement Clarification

1. Controller starts the Architect Agent.
2. Architect Agent inspects the request and current codebase.
3. Architect Agent lists unclear points that affect implementation, acceptance, data contracts, or safety boundaries.
4. Controller asks the user those questions.
5. Architect Agent updates the requirement summary after the user answers.
6. Repeat until the Architect Agent confirms the request is implementable.

Exit gate:

1. Requirement summary is written.
2. `<base-branch>` is detected and written.
3. Acceptance criteria are written.
4. Task split is written.
5. API/module contract is written.
6. Ownership scopes are written.

### Phase 2: Parallel Implementation

1. Controller creates or assigns isolated worktrees for frontend, backend, review, and test work.
2. Controller starts Frontend Agent and Backend Agent in parallel.
3. Frontend Agent implements its scope and runs mock-data or mock-API self-test.
4. Backend Agent implements its scope and runs mock-request or mock-dependency self-test.
5. If frontend and backend discover a contract mismatch, they MUST report it to the Controller. The Architect Agent decides the contract update.

Exit gate:

1. Frontend mock self-test passed.
2. Backend mock self-test passed.
3. Frontend Agent reported the self-tested frontend commit SHA.
4. Backend Agent reported the self-tested backend commit SHA.
5. Both agents reported their actual implemented contract details.

### Phase 3: Code Review

1. Controller starts the Review Agent.
2. Review Agent reviews frontend and backend implementation before integration testing.
3. If review fails, Review Agent lists required changes and the responsible agent.
4. The responsible agent fixes the issue, reruns self-test, and returns to this review phase.

Exit gate:

1. Review Agent explicitly reports `pass`.
2. No required changes remain open.
3. Review Agent reported the approved frontend and backend commit SHAs.

### Phase 4: Integration Testing

1. Controller starts or resumes the Test Agent only after code review passes.
2. Test Agent integrates the reviewed frontend and backend branches into the test worktree.
3. Test Agent runs integration, contract, E2E, or equivalent project verification.
4. If testing fails, Test Agent reports ownership and evidence.
5. Controller sends the failure back to the responsible agent.
6. The responsible agent fixes the issue, returns to Phase 2 self-test, then Phase 3 review, and only then retests integration.

Exit gate:

1. Test Agent explicitly reports integration passed.
2. Test Agent provides commands and results.
3. Test Agent reported the tested frontend and backend commit SHAs.

### Phase 5: Merge

1. Controller starts the Merge Agent.
2. Merge Agent merges the approved frontend, backend, and test branches in the merge worktree.
3. Merge Agent resolves conflicts or requests help from the responsible agent.
4. Merge Agent runs the full verification command set.
5. Merge Agent prepares the result on `<base-branch>`.

Exit gate:

1. Merge Agent explicitly reports merge completed.
2. Full verification passed after merge.
3. `<base-branch>` contains the approved frontend, backend, and test changes.

### Phase 6: Independent Final Verification

1. Controller returns to the Architect Agent.
2. Architect Agent dispatches an independent verification subagent.
3. The verification subagent MUST inspect the real current codebase after merge.
4. The verification subagent MUST judge the code against the original acceptance criteria.
5. If the feature is incomplete, the Architect Agent identifies the responsible phase and sends the workflow back to that phase.
6. If the feature is complete, the Architect Agent reports completion to the Controller.

Final completion gate:

1. All acceptance criteria are satisfied.
2. Frontend mock self-test passed.
3. Backend mock self-test passed.
4. Code review passed before integration testing.
5. Frontend/backend integration passed after review.
6. Merge to `<base-branch>` succeeded.
7. Independent final verification passed against the real current codebase.

## Failure and Rework Rules

1. Requirement unclear: return to Architect Agent and ask the user.
2. Frontend mock self-test failed: Frontend Agent fixes and reruns self-test.
3. Backend mock self-test failed: Backend Agent fixes and reruns self-test.
4. Review failed: Review Agent assigns ownership; responsible agent fixes and reruns self-test, then review runs again.
5. Integration failed: Test Agent assigns ownership; responsible agent fixes and reruns self-test, then review runs again before integration retest.
6. Merge conflict: Merge Agent asks the responsible agent for help when the safe resolution is unclear.
7. Final verification failed: Architect Agent assigns ownership and returns to the correct phase.

After any rework, all later gates MUST run again. No agent may skip directly to final completion.

## Agent Communication Protocol

All cross-agent messages MUST use this structure:

```text
From agent:
To agent:
Subject:
Context:
Required confirmation or change:
Blocking level: blocking / non-blocking
Related files:
Related commands or logs:
```

Any interface or contract change MUST be sent to the Architect Agent. Frontend and Backend Agents MUST NOT independently invent incompatible fields or behavior.

## Controller Final Response Format

When the task is complete, the Controller should reply to the user in the user's preferred language and include:

```text
Task completed.

Completed work:
- ...

Verification:
- Frontend mock self-test: passed, command: ...
- Backend mock self-test: passed, command: ...
- Review: passed
- Integration test: passed, command: ...
- Merge: completed on <base-branch>
- Independent final verification: passed

Key files:
- ...
```

If any part is blocked or incomplete, the Controller MUST NOT claim completion. It MUST state:

```text
Task not completed.

Current phase:
Responsible agent:
Blocking reason:
Next action:
```

## Invocation Template

Use this template for future requests:

```text
Please execute the following request according to docs/codex-multi-agent-team-spec.md:

[Write the development request here.]

Requirements:
1. Start a multi-agent team.
2. Use isolated Git worktrees for all coding agents.
3. Follow every gate in the spec.
4. Report completion only after independent final verification passes.
```
