# GitHub Actions Multi-Region Deployment Demo Script

Audience: Architects / Engineering Team  
Duration: ~20 minutes (plus Q&A)  
Repo: `aspire-demo89x`

## 0. High-Level Flow (Slide/Whiteboard)

Build & Test -> Parallel Dev (eastus + centralus) -> Approval -> Parallel Test (eastus + centralus)

## 1. Agenda (Timebox)

1. Intro & Goal (2m)
2. Core Concepts (Workflows, Reusable, Matrix) (3m)
3. Architecture & YAML Walkthrough (5m)
4. Live Run (Trigger + Observe) (5m)
5. Deep Dive: Matrix + Env + Resource Groups (3m)
6. Observability & Health Checks (1m)
7. Wrap & Q&A (1m)

## 2. Demo Environment Prep (Do BEFORE Session)

- Ensure repo on main branch is clean.
- Confirm GitHub Environments: Dev (no approval), Test (requires approval).
- Validate secrets: AZURE_CLIENT_ID / TENANT / SUBSCRIPTION, optional Log Analytics secrets.
- Pre-created RGs exist: `rg-Dev-eastus`, `rg-Dev-centralus`, `rg-Test-eastus`, `rg-Test-centralus` (regions match names).
- Confirm federated credential is working (a recent successful run).
- Optional: Clear prior azd envs locally if you will run any local commands (not required for CI-only demo).

## 3. Narrative Opening (2m)

Goal: Show how one pipeline reliably deploys .NET Aspire app to multiple Azure regions with minimal YAML duplication and controlled promotion.
Problem: Manual or serial regional rollouts are slow and inconsistent.
Solution: GitHub Actions main workflow orchestrates a build + multi-region fan-out using a matrix, plus a reusable deployment workflow.
Outcome: Faster feedback, resilience, consistency, easy regional scaling.

## 4. Key Concepts (3m)

- Workflow layering: Orchestration vs Reusable ("caller" vs "callee").
- Matrix strategy: Declarative region/environment tuples (explicit include avoids accidental combos).
- Environments: GitHub Environment gates & variables; approval only at Test stage.
- azd + Bicep: Infrastructure and application deployment unified; environment suffix drives naming.
- Resource groups: Passed explicitly to guarantee governance & isolation.

## 5. Show Main Workflow YAML (1m)

Highlight: `strategy.matrix.include` with environment, region, resourceGroup.
Call out: `fail-fast: false` ensures one region failure doesn’t hide the other.
Point at: `needs: build-and-test` then `needs: deploy-dev` for promotion ordering.

## 6. Show Reusable Deploy Workflow (2m)

Highlight env block mapping: AZURE_ENV_NAME, AZURE_LOCATION, AZURE_RESOURCE_GROUP.
Show azd setup step: idempotent env creation + `azd env set` calls.
Mention fallback logic for RG (prevents empty variable failure).
Point at health check loop (12 x 10s = 2m max) – resilience + non-blocking warning.

## 7. Deep Dive: Matrix Mechanics (1m)

Explain: Each row in `include:` becomes a separate job instance.
Scaling: Add a region = add one row; no other YAML changes.
Promotion: Test matrix is held until all Dev matrix jobs finish.
Approval: Single approval releases both Test regional jobs simultaneously.

## 8. Live Run (5m)

Script:

1. Manually trigger (workflow_dispatch) OR push a trivial README change.
2. Open Actions tab; open the new run.
3. Expand `build-and-test` (show it uses reusable build/test).
4. When `deploy-dev` matrix appears, highlight two parallel jobs (eastus / centralus).
5. After completion, show that Test jobs are waiting for approval (if gating enabled) – approve.
6. Show Test region jobs start in parallel.
7. Open one job log; scroll to env setup and provisioning lines; highlight RG name used.
8. Show health check lines -> endpoints & status codes.
9. (Optional) Open Azure Portal: show both RGs populated; show tags (azd-env-name).

## 9. Observability & Logs (1m)

- Optional reuse of existing Log Analytics workspace via secrets (mention only if configured).
- Health endpoint validation ensures early failure detection.
- Resource tagging (azd-env-name) enables filtering in Cost/Monitor.

## 10. Error Handling Talking Points (30s)

- If a region fails: other region continues; partial insight for triage.
- Empty RG var guard prevents silent misconfiguration.
- Idempotent azd env new/select avoids interactive prompt failures.

## 11. Security & Governance (45s)

- Federated OIDC: no long-lived credentials.
- Explicit RG mapping: ensures isolation boundaries & policy compliance.
- Reusable workflow centralizes least-privilege logic.

## 12. Extensibility (45s)

- Add a new region: one matrix line.
- Add Prod stage: copy Test pattern with stricter approval & different suffix.
- Add per-region scaling: add matrix keys (replicas, sku) surfaced to Bicep.
- Future: Canary/Blue-Green by adding axes or conditional strategy.

## 13. Wrap (30s)

Message: Matrix + reusable workflows give scalable multi-region delivery with minimal YAML.
Ask: Which stage do we productionize next (Prod gating, performance tests, canary)?
Call to Action: Identify additional regions or compliance steps for next sprint.

## 14. Q&A Seed Questions

- How to handle secrets rotation with federated identity? (Answer: rotation minimized; only app secrets remain.)
- How to add rollback? (Answer: track artifact versions; rerun deploy with previous version; infra idempotent.)
- Can we parameterize scaling per region? (Yes—add matrix keys, pass to azd env set & Bicep params.)
- How to introduce chaos testing? (Add a post-deploy job conditioned on success for one region.)

## 15. Fallback / Contingency Plan

If Dev provisioning fails: Show logs, highlight fail-fast false, open other region success.
If Test approval delayed: Demo manual cancellation & re-run from build/test job using rerun functionality.
If azd env error: Show env step with create/select pattern, re-run single failed job.

## 16. Optional Command Cheatsheet (Reference Only)

```bash
# List azd environments locally (if needed)
azd env list

# Show environment configuration
azd env get-values -e aspire-Dev-eastus-001

# Validate Bicep locally (optional)
azd provision --preview -e aspire-Dev-eastus-001
```

## 17. Slide / Section Mapping (Quick Index)

| Section | Slide / View | Action |
| ------- | ------------ | ------ |
| 1-4 | Slides | Context setup |
| 5 | VS Code main workflow | Highlight matrix |
| 6 | Reusable deploy YAML | Show env block |
| 7 | Main workflow again | Explain parallelization |
| 8 | GitHub Actions run | Live execution |
| 9 | Portal / Logs | Show resources |
| 10-12 | Slide | Edge cases & future |
| 13 | Slide | Wrap |
| 14 | Slide (backup) | Q&A |

## 18. Key Phrases (Consistency)

"Matrix fan-out" / "Reusable workflow consolidation" / "Idempotent azd environment" / "Explicit RG governance" / "Fail-fast disabled for observability".

---
Prepared: {{DATE}}
