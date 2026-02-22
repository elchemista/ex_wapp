
## Goals

* Improve readability first; performance changes only when profiling proves it matters. 
* Make control flow obvious: fewer branches, less nesting.
* Make contracts explicit with typespecs so refactors stay safe. 

---

## 1) Mandatory conventions for this repo

### Specs / docs

* **Public `def`**: always add `@doc` + `@spec`. 
* **Private `defp`**: always add `@spec` (no `@doc`). 
* If returning tagged tuples, the spec must show the exact shapes. 
* Avoid specs that lie; avoid `term()` everywhere. 

### Logger

* **Never** `require Logger` inside functions. Put it once at module top. 
* Add logs only on **meaningful fallback/unexpected paths**, not “entered function” noise. 

---

## 2) Refactoring workflow

1. Lock behavior with tests (or add minimal tests around the change). 
2. Refactor for clarity (reduce branching/nesting, normalize return shapes). 
3. Add/adjust `@spec` (and `@type`/`@typep`) while intent is fresh. 
4. Run: `mix format`, `mix test`, `mix credo`, `mix dialyzer` (if used). 
5. If performance-related: profile before/after. 

---

## 3) Control-flow selection rules (repo style)

### 3.1 Prefer function heads + guards when the decision is on input shape/type

Use multiple clauses when the decision is based on pattern/shape. 

### 3.2 Use `if` for a single boolean decision

Do not use `cond` for one condition. 

### 3.3 Use `case` when matching on a value/result and it’s clearer than forcing `with`

`case` is appropriate when branching on the shape of a value. 

### 3.4 Use `with` for chained steps (2+), and use it to reduce nesting

`with` is for dependent steps. 

**Repo-specific exception (important):**
It is acceptable (and preferred in this repo) to use `with` **without `else`** for a *single match* when it removes a passthrough error branch (i.e., when failures should return unchanged). This matches the refactor patterns below. 

### 3.5 Use `cond` only for 2+ unrelated boolean branches



---

## 4) Normalize return shapes early

* Prefer `{:ok, value} | {:error, reason}` for operations that can fail. 
* Convert odd shapes at edges so core logic stays uniform. 
* Avoid `with ... else` that mixes unrelated error meanings; fix at the leaf. 

---

## 5) Reduce nesting without over-factoring

* Max one level of nested `if`/`case` inside a function body; split into helpers if needed. 
* Prefer guard clauses / early returns to avoid “pyramid code”. 
* Do not create extra helper functions if they only forward many params or replace a small readable inline block. 

---

## 6) Refactor patterns with BEFORE/AFTER examples

### 6.1 Collapse duplicated heads when the difference is tiny (keep `case`)

Rule: if improvement is “remove duplication” and you still need branching, keep `case`. 

**BEFORE**

```elixir
defp extract_key_index_field(0, 3, rest) do
  case decode_varint(rest) do
    {:ok, value, _tail} -> value
    _ -> nil
  end
end

defp extract_key_index_field(0, _field_num, rest) do
  case decode_varint(rest) do
    {:ok, _value, tail} -> do_extract_key_index(tail)
    _ -> nil
  end
end
```

**AFTER (single head, one decode, keep `case`)**

```elixir
@spec extract_key_index_field(0, non_neg_integer(), binary()) :: non_neg_integer() | nil
defp extract_key_index_field(0, field_num, rest) do
  case decode_varint(rest) do
    {:ok, value, tail} ->
      if field_num == 3, do: value, else: do_extract_key_index(tail)

    _ ->
      nil
  end
end
```

---

### 6.2 Convert `case` → `with` WITHOUT `else` when failures are passthrough

Rule: use `with` without `else` only when the non-matching value is already the correct return value. 

**BEFORE**

```elixir
case decrypt_payload(read_cipher, hash, ciphertext) do
  {:ok, plaintext, new_read_cipher} ->
    {:ok, {write_cipher, new_read_cipher, hash}, plaintext}

  {:error, reason} ->
    {:error, reason}
end
```

**AFTER (no `else`)**

```elixir
@spec decrypt_and_wrap(term(), term(), binary(), term()) ::
        {:ok, {term(), term(), term()}, binary()} | {:error, term()}
defp decrypt_and_wrap(write_cipher, read_cipher, ciphertext, hash) do
  with {:ok, plaintext, new_read_cipher} <- decrypt_payload(read_cipher, hash, ciphertext) do
    {:ok, {write_cipher, new_read_cipher, hash}, plaintext}
  end
end
```

---

### 6.3 Convert “do work only on error, otherwise pass through” using inverted `with` WITHOUT `else`

Rule: if success should pass through untouched and only error needs transformation, match the error in the `with`. 

**BEFORE**

```elixir
defp decode_details_relaxed(details) do
  case decode_details(details) do
    {:ok, decoded} ->
      {:ok, decoded}

    {:error, reason} ->
      key_index = extract_key_index_from_details_blob(details)

      Logger.warning(
        "[ADV] decode_details_relaxed: falling back to partial details, " <>
          "keyIndex=#{inspect(key_index)} reason=#{inspect(reason)}"
      )

      {:ok, %{keyIndex: key_index, decode_error: reason}}
  end
end
```

**AFTER (no `else`, success passes through untouched)**

```elixir
@spec decode_details_relaxed(binary()) :: {:ok, map()}
defp decode_details_relaxed(details) do
  with {:error, reason} <- decode_details(details) do
    key_index = extract_key_index_from_details_blob(details)

    Logger.warning(
      "[ADV] decode_details_relaxed: falling back to partial details, " <>
        "keyIndex=#{inspect(key_index)} reason=#{inspect(reason)}"
    )

    {:ok, %{keyIndex: key_index, decode_error: reason}}
  end
end
```

---

### 6.4 Convert multi-step nested `case` to `with` WITH `else` when fallback must be normalized/logged

Rule: use `else` when you must transform any failure into a specific fallback return (and/or log). 

**BEFORE**

```elixir
defp try_hmac_or_fallback(direct_result, adv_bytes, adv_secret, identity_pub, identity_priv) do
  case decode_container(adv_bytes) do
    {:ok, container}
    when is_binary(container.details) and byte_size(container.details) > 0 ->
      case parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv) do
        {:ok, wrapped} ->
          {:ok, wrapped}

        {:error, _reason} ->
          Logger.info("[ADV] Falling back to direct parse result")
          {:ok, direct_result}
      end

    _ ->
      Logger.info("[ADV] Falling back to direct parse result")
      {:ok, direct_result}
  end
end
```

**AFTER (`with` pipeline + single `else`)**

```elixir
@spec try_hmac_or_fallback(term(), binary(), binary(), binary(), binary()) :: {:ok, term()}
defp try_hmac_or_fallback(direct_result, adv_bytes, adv_secret, identity_pub, identity_priv) do
  with {:ok, container} <- decode_container(adv_bytes),
       true <- is_binary(container.details) and byte_size(container.details) > 0,
       {:ok, wrapped} <- parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv) do
    {:ok, wrapped}
  else
    _ ->
      Logger.info("[ADV] Falling back to direct parse result")
      {:ok, direct_result}
  end
end
```

---

## 7) Quick anti-pattern list (remove during refactors)

* `cond` with one condition → use `if`. 
* `case` that only checks a boolean → use `if`. 
* Big `case` on shapes that could be function clauses → use multiple clauses + guards. 
* Inconsistent return tuples across helpers (forces messy callers). 
* Avoid noisy logs; log only meaningful fallbacks/unexpected states. 

---

## 8) Checklist for a good refactor PR

* [ ] Public API functions have correct `@doc` + `@spec`. 
* [ ] Private helpers have `@spec` when non-trivial (repo convention: always for `defp`). 
* [ ] `require Logger` only at module head; logs only on meaningful fallback/unexpected paths. 
* [ ] Use `with` to reduce nesting; no-`else` `with` is used only when failures pass through unchanged or when matching the “special” branch (e.g. error-first). 
* [ ] Return shapes normalized (`{:ok, _} | {:error, _}`) where appropriate. 
* [ ] `mix format`, tests, and (if enabled) Dialyzer pass. 
