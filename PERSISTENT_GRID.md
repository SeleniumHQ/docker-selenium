# Persistent Grid Adaptation for docker-selenium

This document describes how to adapt `docker-selenium` to run Selenium Grid in a persistent, horizontally scalable distributed mode using external state services.

The target control-plane stack is:

- `Redis Cluster` for persistent Grid coordination state
- `NATS Server` with `JetStream` enabled for the brokered Grid event bus
- Selenium Grid roles deployed as separate containers:
  - `router`
  - `distributor`
  - `session-queue`
  - `sessions`
  - browser `node-*`
  - optional `event-bus` compatibility container

This is a design and rollout spec for `docker-selenium`. It is intentionally separate from the Java implementation spec in the Selenium monorepo.

## Goals

- Adapt `docker-selenium` startup scripts, env vars, and examples to the persistent Grid architecture implemented in Selenium Grid.
- Make multi-replica `Router`, `Distributor`, `SessionMap`, `SessionQueue`, and `EventBus` practical in container environments.
- Keep the current images and execution modes compatible while adding a clear opt-in path for persistent mode.
- Preserve the current `docker compose`, Helm, and Kubernetes operator experience as much as possible.

## Non-goals

- Replacing existing ZeroMQ-based examples immediately.
- Removing the legacy `event-bus` image or container role in the first phase.
- Defining the Java-side persistence algorithms. Those live in the Selenium server design docs.

## Current state in docker-selenium

Today `docker-selenium` is still aligned with the classic Grid distributed topology:

- components derive `--publish-events` and `--subscribe-events` from `SE_EVENT_BUS_HOST`, `SE_EVENT_BUS_PUBLISH_PORT`, and `SE_EVENT_BUS_SUBSCRIBE_PORT`
- the `event-bus` container starts the built-in Selenium Event Bus service
- the external datastore example only externalizes `SessionMap`
- `Distributor` and `SessionQueue` remain process-local
- video event-driven mode assumes Grid events are available through the current event bus setup

This means the current Docker images are not yet sufficient to run the full persistent architecture, even if the Java server already provides Redis-backed or NATS-backed implementations.


## Compatibility and regression check

The current `docker-selenium` changes for persistent mode are designed to be additive.

- Classic distributed mode remains driven by `SE_EVENT_BUS_HOST`, `SE_EVENT_BUS_PUBLISH_PORT`, and `SE_EVENT_BUS_SUBSCRIBE_PORT` when `SE_EVENT_BUS_IMPLEMENTATION` is unset.
- Brokered event-bus settings such as `SE_EVENT_BUS_URL`, `SE_EVENT_BUS_STREAM`, `SE_EVENT_BUS_SUBJECT_PREFIX`, `SE_EVENT_BUS_COMPONENT`, and `SE_EVENT_BUS_INSTANCE_ID` are opt-in and do not affect classic mode unless `SE_EVENT_BUS_IMPLEMENTATION` is set.
- Persistent-role settings such as `SE_SESSION_QUEUE_IMPLEMENTATION`, `SE_SESSION_QUEUE_BACKEND_URI`, `SE_SESSION_QUEUE_RESULT_POLL_INTERVAL`, `SE_SESSION_QUEUE_CLAIM_TIMEOUT`, `SE_DISTRIBUTOR_IMPLEMENTATION`, and `SE_DISTRIBUTOR_BACKEND_URI` are additive and have no effect when unset.
- `SE_SESSION_QUEUE_IMPLEMENTATION` is not mapped to a Selenium CLI flag. `docker-selenium` applies it by generating a temporary `[sessionqueue]` TOML file and passing `--config`, which avoids breaking the existing session-queue startup path.
- Based on the current startup-script branching, no breaking change is expected for existing compose files and env-var sets that stay on the default ZeroMQ/non-persistent path.

## Target architecture in docker-selenium

The adapted deployment model is:

```text
             +-------------------+
             |      Router       |
             +-------------------+
                |       |      |
                |       |      +------------------------+
                |       |                               |
                v       v                               v
        +--------------+  +----------------+   +-------------------+
        | SessionQueue |  |   SessionMap   |   |    Distributor    |
        +--------------+  +----------------+   +-------------------+
                |                 |                       |
                |                 |                       |
                +-----------------+-----------+-----------+
                                              |
                                              v
                                      +---------------+
                                      |     Nodes     |
                                      +---------------+

External services:
- Redis Cluster: authoritative persistent state for queue, distributor, sessions, leases
- NATS JetStream: brokered event bus for Grid lifecycle events
```

## Role of Redis and NATS

### Redis

Redis is the source of truth for hot control-plane coordination state:

- session queue request records
- queue claims and result handoff
- node registrations and liveness leases
- slot reservations and slot release
- capability indexes
- session map records when `RedisBackedSessionMap` is used

Redis is not optional for the persistent `Distributor` and persistent `SessionQueue` design.

### NATS JetStream

NATS JetStream is the Grid event transport:

- node lifecycle notifications
- session lifecycle notifications
- audit and reconciliation event replay
- optional consumers such as video upload/event-driven services

NATS is not the authoritative source of current slot or node state. It carries events; Redis carries current truth.

## Component mapping in docker-selenium

### Router

No architectural change is required in the image contract. `router` remains stateless from the container perspective.

Required configuration continues to be:

- `SE_DISTRIBUTOR_HOST`
- `SE_DISTRIBUTOR_PORT`
- `SE_SESSIONS_MAP_HOST`
- `SE_SESSIONS_MAP_PORT`
- `SE_SESSION_QUEUE_HOST`
- `SE_SESSION_QUEUE_PORT`

No direct Redis or NATS dependency is required for `router` in phase 1 unless the Java implementation itself requires it.

### Sessions

`sessions` becomes the persistent session map endpoint. In persistent mode, the container must be able to select a persistent session map implementation.

For Redis-backed sessions map, `docker-selenium` should support:

- `SE_SESSIONS_MAP_EXTERNAL_DATASTORE=true`
- `SE_SESSIONS_MAP_EXTERNAL_IMPLEMENTATION=org.openqa.selenium.grid.sessionmap.redis.RedisBackedSessionMap`
- `SE_SESSIONS_MAP_EXTERNAL_BACKEND_URI=redis://<redis-host>:<redis-port>`

JDBC-backed `SessionMap` remains a supported alternative, but it is not the preferred hot-path store for large-scale control-plane workloads.

### Session Queue

`session-queue` must move from the default in-memory implementation to the persistent Redis-backed implementation.

This requires a new env-var surface in `docker-selenium` so the image can append the right Selenium CLI options without forcing users to pack everything into `SE_OPTS`.

Implemented variables:

- `SE_SESSION_QUEUE_IMPLEMENTATION`
- `SE_SESSION_QUEUE_BACKEND_URI`
- `SE_SESSION_QUEUE_RESULT_POLL_INTERVAL`
- `SE_SESSION_QUEUE_CLAIM_TIMEOUT`

Existing generic queue timing variables are reused:

- `SE_SESSION_REQUEST_TIMEOUT`
- `SE_SESSION_RETRY_INTERVAL`

Recommended value:

- `SE_SESSION_QUEUE_IMPLEMENTATION=org.openqa.selenium.grid.sessionqueue.redis.RedisBackedNewSessionQueue`

### Distributor

`distributor` must move from the default local implementation to the persistent Redis-backed implementation.

Implemented variables:

- `SE_DISTRIBUTOR_IMPLEMENTATION`
- `SE_DISTRIBUTOR_BACKEND_URI`

Existing distributor variables are reused:

- `SE_DISTRIBUTOR_SLOT_SELECTOR`
- `SE_HEALTHCHECK_INTERVAL`

Recommended value:

- `SE_DISTRIBUTOR_IMPLEMENTATION=org.openqa.selenium.grid.distributor.redis.RedisBackedDistributor`

### Nodes

Nodes do not become fully stateful themselves, but their registration and lifecycle traffic must target the brokered event bus instead of the legacy ZeroMQ-only model.

That requires `docker-selenium` to stop assuming that the only valid event-bus wiring is:

- `SE_EVENT_BUS_HOST`
- `SE_EVENT_BUS_PUBLISH_PORT`
- `SE_EVENT_BUS_SUBSCRIBE_PORT`

Persistent mode needs the ability to configure a non-default event bus implementation and broker endpoint.

Proposed variables:

- `SE_EVENT_BUS_IMPLEMENTATION`
- `SE_EVENT_BUS_URL`
- `SE_EVENT_BUS_STREAM`
- `SE_EVENT_BUS_SUBJECT_PREFIX`
- `SE_EVENT_BUS_COMPONENT`
- `SE_EVENT_BUS_INSTANCE_ID` optional, defaults to `<component>-<hostname>` inside the container

Recommended value:

- `SE_EVENT_BUS_IMPLEMENTATION=org.openqa.selenium.events.nats.NatsEventBus`

### Event Bus container

With NATS, the dedicated Selenium `event-bus` container is no longer the message broker. The broker is the external `nats` service.

There are two viable modes for `docker-selenium`:

1. Preferred: no Selenium `event-bus` container in persistent mode.
2. Compatibility: keep the `event-bus` image as a lightweight compatibility service only if the Java implementation still expects a Grid role endpoint for status/readiness.

The default compose example for persistent mode should use a real `nats` container or external NATS cluster, not `selenium/event-bus`.

## Required docker-selenium changes

### 1. Startup script abstraction for event bus configuration

The current scripts assume ZeroMQ and build `--publish-events` plus `--subscribe-events` directly from host and port env vars.

Persistent mode requires a split:

- legacy mode: keep current ZeroMQ behavior untouched
- persistent mode: if `SE_EVENT_BUS_IMPLEMENTATION` is set, do not force `SE_EVENT_BUS_HOST`, `SE_EVENT_BUS_PUBLISH_PORT`, or `SE_EVENT_BUS_SUBSCRIBE_PORT`

New startup-script behavior:

- if `SE_EVENT_BUS_IMPLEMENTATION` is unset:
  - preserve existing ZeroMQ behavior
- if `SE_EVENT_BUS_IMPLEMENTATION` is set:
  - append `--events-implementation`
  - append NATS-specific options from `SE_EVENT_BUS_URL`, `SE_EVENT_BUS_STREAM`, and related env vars
  - skip ZeroMQ-only validation

Scripts affected:

- `Distributor/start-selenium-grid-distributor.sh`
- `Sessions/start-selenium-grid-sessions.sh`
- `SessionQueue/start-selenium-grid-session-queue.sh`
- `Router/start-selenium-grid-router.sh` if it later needs broker config
- `NodeBase/start-selenium-node.sh`
- `EventBus/start-selenium-grid-eventbus.sh`
- any Standalone or Dynamic Grid wrapper that currently injects ZeroMQ-only settings

### 2. New env-var surface for persistent Grid

`docker-selenium` should document first-class env vars for persistent mode instead of requiring `SE_OPTS` escape hatches.

Current implemented additions:

#### NATS

- `SE_EVENT_BUS_URL`
- `SE_EVENT_BUS_STREAM`
- `SE_EVENT_BUS_SUBJECT_PREFIX`
- `SE_EVENT_BUS_COMPONENT`
- `SE_EVENT_BUS_INSTANCE_ID` optional, defaults to `<component>-<hostname>` inside the container

#### Redis-backed Session Queue

- `SE_SESSION_QUEUE_IMPLEMENTATION`
- `SE_SESSION_QUEUE_BACKEND_URI`
- `SE_SESSION_QUEUE_RESULT_POLL_INTERVAL`
- `SE_SESSION_QUEUE_CLAIM_TIMEOUT`

#### Redis-backed Distributor

- `SE_DISTRIBUTOR_IMPLEMENTATION`
- `SE_DISTRIBUTOR_BACKEND_URI`

### 3. New compose example for persistent mode

The current external datastore example only proves external `SessionMap`.

`docker-selenium` should add a new example file, for example:

- `docker-compose-v3-full-grid-persistent.yml`

This file should demonstrate:

- `nats` service with JetStream enabled
- `redis` service
- `sessions` using `RedisBackedSessionMap`
- `session-queue` using `RedisBackedNewSessionQueue`
- `distributor` using `RedisBackedDistributor`
- `router` unchanged except for upstream endpoints
- browser nodes using `NatsEventBus`

The existing `docker-compose-v3-full-grid-external-datastore.yml` should remain as the lower-risk, currently supported example.

### 4. Video recorder and event-driven sidecars

The video event-driven path currently describes the Grid event bus in ZeroMQ terms.

Persistent mode adaptation requires:

- allowing video/event-driven containers to consume Grid lifecycle events from NATS
- keeping existing event-driven behavior intact for ZeroMQ deployments
- documenting which subjects/streams are consumed for session start, session end, and failure events

This is especially important because `SE_VIDEO_EVENT_DRIVEN=true` is already the default.

### 5. Dynamic Grid adaptation

`NodeDocker` and `NodeKubernetes` should not require architectural redesign, but the parent node container must be able to register through the persistent event-bus path.

Implications:

- `NodeDocker/config.toml` and `NodeKubernetes/config.toml` stay structurally valid
- the dynamic node parent image needs the same NATS event bus env-var support as static browser nodes
- child browser containers or jobs do not need Redis access unless the Java implementation explicitly requires it

### 6. Helm and Kubernetes alignment

This spec focuses on the Docker images and compose examples, but the same env-var model should be reused by the Helm chart.

Kubernetes target deployment:

- `router`: `Deployment`, multi-replica
- `distributor`: `Deployment`, multi-replica
- `session-queue`: `Deployment`, multi-replica
- `sessions`: `Deployment`, multi-replica
- `nats`: external managed service or stateful cluster
- `redis`: external managed service or stateful cluster
- browser nodes: `Deployment`, `Job`, or dynamic node launcher as today

The container contract should not diverge between Docker Compose and Helm.

## Current env-var contract for persistent mode

The following variables are currently documented in `ENV_VARIABLES.md` for the persistent path.

| ENV variable | Example | Purpose |
|--------------|---------|---------|
| `SE_EVENT_BUS_IMPLEMENTATION` | `org.openqa.selenium.events.nats.NatsEventBus` | Select NATS-backed event bus implementation |
| `SE_EVENT_BUS_URL` | `nats://nats:4222` | NATS server endpoint |
| `SE_EVENT_BUS_STREAM` | `grid-events` | JetStream stream name |
| `SE_EVENT_BUS_SUBJECT_PREFIX` | `grid` | Subject namespace prefix |
| `SE_EVENT_BUS_COMPONENT` | `node` | Component identity used by event-bus client |
| `SE_EVENT_BUS_INSTANCE_ID` | optional | Stable instance identifier for logs and durable consumers; defaults to `<component>-<hostname>` |
| `SE_SESSION_QUEUE_IMPLEMENTATION` | `org.openqa.selenium.grid.sessionqueue.redis.RedisBackedNewSessionQueue` | Select persistent queue implementation |
| `SE_SESSION_QUEUE_BACKEND_URI` | `redis://redis:6379` | Redis endpoint for queue state |
| `SE_SESSION_QUEUE_RESULT_POLL_INTERVAL` | `200` | Poll interval in ms for request result lookup |
| `SE_SESSION_QUEUE_CLAIM_TIMEOUT` | `30` | Claim lease timeout in seconds |
| `SE_DISTRIBUTOR_IMPLEMENTATION` | `org.openqa.selenium.grid.distributor.redis.RedisBackedDistributor` | Select persistent distributor implementation |
| `SE_DISTRIBUTOR_BACKEND_URI` | `redis://redis:6379` | Redis endpoint for distributor state |

The current implementation intentionally keeps these settings opt-in so existing ZeroMQ-based deployments do not have to change their environment-variable sets.

## Compose topology recommendation

For a local or single-host demonstration, the persistent example should look like this:

```yaml
services:
  nats:
    image: nats:latest
    command: ["--jetstream"]

  redis:
    image: redis:latest

  selenium-sessions:
    environment:
      - SE_SESSIONS_MAP_EXTERNAL_DATASTORE=true
      - SE_SESSIONS_MAP_EXTERNAL_IMPLEMENTATION=org.openqa.selenium.grid.sessionmap.redis.RedisBackedSessionMap
      - SE_SESSIONS_MAP_EXTERNAL_BACKEND_URI=redis://redis:6379
      - SE_EVENT_BUS_IMPLEMENTATION=org.openqa.selenium.events.nats.NatsEventBus
      - SE_EVENT_BUS_URL=nats://nats:4222

  selenium-session-queue:
    environment:
      - SE_SESSION_QUEUE_IMPLEMENTATION=org.openqa.selenium.grid.sessionqueue.redis.RedisBackedNewSessionQueue
      - SE_SESSION_QUEUE_BACKEND_URI=redis://redis:6379
      - SE_EVENT_BUS_IMPLEMENTATION=org.openqa.selenium.events.nats.NatsEventBus
      - SE_EVENT_BUS_URL=nats://nats:4222

  selenium-distributor:
    environment:
      - SE_DISTRIBUTOR_IMPLEMENTATION=org.openqa.selenium.grid.distributor.redis.RedisBackedDistributor
      - SE_DISTRIBUTOR_BACKEND_URI=redis://redis:6379
      - SE_EVENT_BUS_IMPLEMENTATION=org.openqa.selenium.events.nats.NatsEventBus
      - SE_EVENT_BUS_URL=nats://nats:4222

  chrome:
    environment:
      - SE_EVENT_BUS_IMPLEMENTATION=org.openqa.selenium.events.nats.NatsEventBus
      - SE_EVENT_BUS_URL=nats://nats:4222
```

This example is illustrative. The repository should only add it once the image scripts understand the new env vars.

## Rollout plan

### Phase 1: spec and env-var contract

- add this document
- define proposed env vars in `ENV_VARIABLES.md`
- keep legacy examples as-is

### Phase 2: container startup scripts

- update startup scripts to support implementation-selected event bus wiring
- add Redis-backed queue and distributor env-var translation
- keep backward compatibility with existing ZeroMQ env vars

### Phase 3: compose examples

- add `docker-compose-v3-full-grid-persistent.yml`
- keep `docker-compose-v3-full-grid-external-datastore.yml` for current behavior
- document when to use each file

### Phase 4: Helm and dynamic Grid parity

- reuse the same env vars in Helm chart values
- add NATS-backed event bus support to event-driven sidecars
- document Kubernetes deployment patterns using external Redis and NATS

## Compatibility rules

- Existing users of `SE_EVENT_BUS_HOST`, `SE_EVENT_BUS_PUBLISH_PORT`, and `SE_EVENT_BUS_SUBSCRIBE_PORT` must not break.
- Existing `docker-compose-v3-full-grid.yml` and `docker-compose-v3-full-grid-external-datastore.yml` files remain valid.
- Persistent mode must be opt-in.
- The persistent example should not be marked production-ready until:
  - the Java server implementation is complete
  - the container startup scripts support the new env vars
  - compose and Helm examples have been verified end-to-end

## Open questions

- Should the persistent mode keep a `selenium/event-bus` container at all, or should `nats` be the only broker service in the example topology?
- Should `docker-selenium` expose one generic `SE_REDIS_URI` for all persistent roles, or preserve separate env vars per role?
- Should video/event-driven services consume JetStream streams directly, or should they continue through a Grid-side event-bus compatibility layer?
- Which NATS client options need first-class env vars beyond URL, stream, and subject prefix?

## Implementation status

Implemented in the current experimental path:

1. Brokered event-bus env vars are documented and startup scripts bypass ZeroMQ-only validation when `SE_EVENT_BUS_IMPLEMENTATION` is set.
2. Persistent-role env vars are wired for `session-queue` and `distributor`, with a dedicated persistent compose example using `redis` plus `nats`.
3. `SE_EVENT_BUS_INSTANCE_ID` is optional and auto-derives to `<component>-<hostname>` when omitted.

Still experimental / not production-ready:

1. End-to-end runtime verification for all persistent roles and scale profiles is still required.
2. Video/event-driven docs still need a NATS-specific operational walkthrough.
3. Prefix-style Redis env vars are not part of the current container contract and should not be documented as supported until implemented.
