# Session Trust + Protocol Parity Checklist

This checklist defines the next hardening phase focused on:
- WhatsApp trust-model risk for unofficial clients
- ADV/handshake/auth protocol-parity risk

All controls are designed to be configured per account/session via `runtime: [...]`.

## 1. Session-Level Config Surface

Use per-session overrides when starting a session:

```elixir
{:ok, session} =
  ExWapp.Session.Supervisor.start_session("acc_1",
    store: {ExWapp.Store.Ets, path: "tmp/ex_wapp/acc_1.etf"},
    runtime: [
      compliance: [strict_mode: true],
      risk: [block_threshold: 75],
      canary: [enabled: true, recipients: ["15551234567@s.whatsapp.net"]]
    ]
  )
```

Global defaults can still be set in `config :ex_wapp, :runtime`.

## 2. Controls to Implement

### 2.1 Strict Compliance Mode

Status: `config-ready`

- [ ] Enforce explicit opt-in before first outbound message
- [ ] Enforce opt-out suppression (hard block)
- [ ] Enforce high-risk fan-out limits for new JIDs and groups
- [ ] Emit compliance telemetry on every blocked send

Runtime keys:
- `[:compliance, :strict_mode]`
- `[:compliance, :require_explicit_opt_in]`
- `[:compliance, :enforce_opt_out]`
- `[:compliance, :high_risk_fanout, :max_new_jids_per_hour]`
- `[:compliance, :high_risk_fanout, :max_groups_per_hour]`
- `[:compliance, :high_risk_fanout, :max_mentions_per_hour]`
- `[:compliance, :on_violation]`

### 2.2 Adaptive Sending Governor

Status: `config-ready`

- [ ] Track auth/delivery/retry stress signals in rolling windows
- [ ] Dynamically scale effective send throughput
- [ ] Restore throughput gradually after stable period
- [ ] Add governor level to `policy_status/1`

Runtime keys:
- `[:adaptive_governor, :enabled]`
- `[:adaptive_governor, :baseline_mps]`
- `[:adaptive_governor, :min_mps]`
- `[:adaptive_governor, :degrade_step]`
- `[:adaptive_governor, :recovery_step]`
- `[:adaptive_governor, :signal_weights, ...]`

### 2.3 Account Risk Score + Circuit Breaker

Status: `config-ready`

- [ ] Maintain per-session risk score with weighted signals
- [ ] Decay score over time
- [ ] Trigger circuit break when threshold is crossed
- [ ] Require manual reset when `manual_unblock_required` is enabled

Runtime keys:
- `[:risk, :enabled]`
- `[:risk, :block_threshold]`
- `[:risk, :decay_per_minute]`
- `[:risk, :manual_unblock_required]`
- `[:risk, :cooloff_ms]`
- `[:risk, :weights, ...]`

### 2.4 Canary Numbers + Synthetic Tests

Status: `config-ready`

- [ ] Scheduled canary cycle per session
- [ ] Checks: login, send text, send media, group send
- [ ] Fail-fast after N consecutive failures
- [ ] Auto-trip safety/circuit breaker on persistent canary failure

Runtime keys:
- `[:canary, :enabled]`
- `[:canary, :interval_ms]`
- `[:canary, :recipients]`
- `[:canary, :checks, :login]`
- `[:canary, :checks, :send_text]`
- `[:canary, :checks, :send_media]`
- `[:canary, :checks, :group_send]`
- `[:canary, :fail_fast_consecutive_failures]`

### 2.5 Release Gates + Kill Switch + Rollback

Status: `config-ready`

- [ ] Gate risky send/auth features behind feature flags
- [ ] Implement remote kill switch polling source
- [ ] Apply `rollback_profile` to enforce safe runtime subset
- [ ] Persist last-known-good profile per session

Runtime keys:
- `[:release_gates, :enabled]`
- `[:release_gates, :remote_kill_switch]`
- `[:release_gates, :rollback_profile]`
- `[:release_gates, :feature_flags]`
- `[:release_gates, :blocked_features]`

### 2.6 Auth Churn Minimization

Status: `config-ready`

- [ ] Rate-limit reauth/repair attempts in windows
- [ ] Add cooldown before re-pair after auth failure loops
- [ ] Telemetry for auth churn and lockouts

Runtime keys:
- `[:auth_guard, :max_repair_attempts_per_hour]`
- `[:auth_guard, :max_reauth_attempts_per_day]`
- `[:auth_guard, :reauth_cooldown_ms]`
- `[:auth_guard, :re_pair_cooldown_ms]`

### 2.7 Protocol Health Telemetry + Alerts

Status: `config-ready`

- [ ] Counters for bad MAC / prekey misses / session mismatch
- [ ] Sliding-window alerting thresholds
- [ ] Correlate spikes with build/version metadata

Runtime keys:
- `[:protocol_health, :enabled]`
- `[:protocol_health, :alert_thresholds, :bad_mac_per_minute]`
- `[:protocol_health, :alert_thresholds, :prekey_miss_per_minute]`
- `[:protocol_health, :alert_thresholds, :session_mismatch_per_minute]`

### 2.8 Device/Session Hygiene Checks

Status: `config-ready`

- [ ] Detect concurrent use of same store/session identity
- [ ] Detect frequent fingerprint/resource drift
- [ ] Auto-block risky reconnect loops caused by drift

Runtime keys:
- `[:hygiene, :enabled]`
- `[:hygiene, :prevent_concurrent_store_use]`
- `[:hygiene, :enforce_stable_resource]`
- `[:hygiene, :max_fingerprint_changes_per_day]`

### 2.9 Enforcement Playbook Automation

Status: `config-ready`

- [ ] Snapshot diagnostics on policy/auth enforcement signals
- [ ] Include bounded event history for investigation
- [ ] Export structured incident bundle for support/appeal workflows

Runtime keys:
- `[:enforcement, :enabled]`
- `[:enforcement, :snapshot_on_signals]`
- `[:enforcement, :include_runtime_config]`
- `[:enforcement, :capture_last_events]`
- `[:enforcement, :max_snapshot_bytes]`

## 3. Firefox/Linux Client Identity

Current state:
- client payload now supports runtime-configured Firefox/Linux user-agent defaults
- values can be overridden per session using `runtime: [protocol: [user_agent: [...]]]`

Next checks:
- [ ] Compare user-agent payload fields against a fresh WhatsApp Web Firefox/Linux capture
- [ ] Validate stability over reconnects (avoid frequent fingerprint drift)
- [ ] Keep identity values consistent per account over time

## 4. Rollout Plan

- [ ] Phase 1: shadow mode (metrics + logs only, no hard blocks)
- [ ] Phase 2: soft enforcement (`warn_only` where available)
- [ ] Phase 3: strict enforcement per high-risk accounts
- [ ] Phase 4: default strict mode for all new sessions

## 5. Test Gates

- [ ] Unit tests for each config validator branch
- [ ] Unit tests for risk score transitions and breaker behavior
- [ ] Integration tests for canary failure -> circuit break flow
- [ ] Integration tests for auth cooldown windows
- [ ] Regression tests to ensure no impact on currently passing flows
