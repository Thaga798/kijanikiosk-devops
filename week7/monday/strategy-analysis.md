# Week 7 Monday: Deployment Strategy Analysis

## Scenario 1: The Overnight Batch Processor

**Selected strategy: Rolling deployment**

Rolling deployment avoids the cost of maintaining duplicate servers, which fits the minimal budget and single-worker setup. Since the job runs overnight and rollback within 24 hours is acceptable, the team can update the worker during the scheduled window, although it must protect against mixed-version processing and incorrect output formats.

## Scenario 2: The User-Facing Authentication Service

**Selected strategy: Blue/Green deployment**

Blue/Green is appropriate because the team can afford double the server count and can switch traffic back to the stable environment quickly if authentication failures exceed 1%. Since JWT tokens are not backwards-compatible, the switch must be treated as an atomic cutover, with a plan for existing sessions and tokens because switching environments alone cannot make tokens from one version valid in the other.

## Scenario 3: The Machine Learning Recommendation Engine

**Selected strategy: Canary deployment**

Canary deployment allows v3.0 to serve a small share of users while v2.8 remains available, limiting the impact of increased compute use or poor performance. At the 10% and 50% stages, collect click-through rate (CTR), p95 latency, error rate, and compute usage for each model; proceed only if reliability and latency remain within SLOs and CTR results support improvement, otherwise route all traffic back to v2.8.

### Canary Rollout: Data and Go/No-Go Decisions

**Baseline — v2.8 at 100%**

Record CTR, p95 latency, error rate, and compute usage per request.  
**Go:** baseline is stable and the measurement window is sufficient.  
**No-go:** metrics are unstable or monitoring is incomplete.

**Stage 1 — v3.0 at 10%**

Keep v2.8 serving the remaining 90% and compare both models using the same metrics.  
**Go:** v3.0 meets reliability and latency SLOs, compute usage is acceptable, and no serious regression appears.  
**No-go:** errors rise, latency breaches SLOs, compute exceeds budget, or CTR shows a concerning decline; route 100% back to v2.8.

**Stage 2 — v3.0 at 50%**

Increase exposure only after the 10% stage passes, then compare CTR, latency, errors, and compute costs across both versions.  
**Go:** performance remains within SLOs and CTR improvement is supported by sufficient data.  
**No-go:** any critical threshold fails or results show no worthwhile benefit; route all traffic back to v2.8.

**Stage 3 — Full rollout**

Move to 100% only after the 50% stage passes and the results are reliable enough to support the decision. Continue monitoring the same metrics after rollout. If reliability, latency, or compute limits are breached, roll back to v2.8.

Rollback must remain available at every stage, and the team should define numeric thresholds before the rollout begins.
