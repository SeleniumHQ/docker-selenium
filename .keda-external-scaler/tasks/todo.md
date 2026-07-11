# TODO — Selenium Grid KEDA External Scaler

Live checklist. Authoritative plan: `../../.claude/plans/steady-snuggling-whistle.md`
(approved) and `../PLAN.md`. Gates marked with ★.

- [x] T1 — Module scaffold + generated gRPC stubs
- [x] T2 — Port pure scaling logic (types/logic/platform)
- [x] T3 — Port upstream test table ★ GATE 1 (52 getCount cases verbatim; 4 strategy cases in T6)
- [x] T4 — Metadata parser with env fallback
- [x] T5 — Grid GraphQL client
- [x] T6 — gRPC server implementation ★ GATE 2 (incl. ported strategy cases)
- [x] T7 — Binary entrypoint (TLS/health/shutdown)
- [x] T8 — Container image ★ GATE 3 (multi-arch)
- [x] T9 — Standalone deploy manifests + module README
- [x] T10 — Helm chart wiring ★ GATE 4
- [x] T11 — Chart docs + migration notes

All tasks complete.
