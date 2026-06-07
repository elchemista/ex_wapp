# SKILL.md

## Elixir style rules (high signal)

* Lists do not support index access. Use `Enum.at/2` or pattern matching.
* Bind the result of `if/case/cond` if you need it (immutable variables).
* Do not create multiple modules in one file.
* Avoid `String.to_atom/1` on user input.

---

## Refactoring

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


# 9) First principles

* **Measure, don’t guess.** Use `mix profile.fprof`, `mix profile.eprof`, `:timer.tc/1`, and a micro-bench tool like Benchee. Optimize only the hottest 5–10%.
* **Keep data immutable and local.** Fewer copies, fewer surprises.
* **Processes are for isolation and concurrency, not “organization.”** Libraries should export pure functions; application code decides when to parallelize.

# 10) Hot-path patterns

## Pattern matching beats branching

Prefer multi-clause + guards to big `case`/`if`.

```elixir
def parse(<<"OK:", rest::binary>>), do: {:ok, rest}
def parse(<<"ERR:", rest::binary>>), do: {:error, rest}
def parse(_), do: {:error, :bad_prefix}
```

Benefits: no conditionals, no allocations for failed branches.

## Build lists by prepending, not appending

* Prepend: `new_list = [x | acc]` is O(1).
* Append: `list ++ [x]` is O(n). Avoid in loops.
* If you need forward order:

```elixir
acc = Enum.reduce(items, [], fn x, acc -> [transform(x) | acc] end)
Enum.reverse(acc)
```

If concatenation is inevitable, ensure the **left list is small or constant**: `[1,2,3] ++ big_list`.

## Use iodata for text/binary assembly

Don’t `<>` in loops. Return iodata and let sinks flatten.

```elixir
def render(rows) do
  rows
  |> Enum.map(fn {a,b} -> [Integer.to_string(a), ":", b, ?\n] end)
end

# IO handles it:
IO.iodata_to_binary(render(rows)) |> IO.write()
```

## Binary pattern matching > repeated String ops

```elixir
def take_ext(<<rest::binary-size(sz - 4), ".", ext::binary>>) when sz >= 5, do: ext
def take_ext(_), do: nil
```

This avoids intermediate binaries.

## Prefer streams on large pipelines

`Stream` defers work and avoids intermediate lists:

```elixir
input
|> Stream.map(&decode/1)
|> Stream.reject(&bad?/1)
|> Enum.reduce(%{}, &merge/2)
```

Use `Enum` when data is modest and clarity wins.

## Choose data structures consciously

* Membership checks: `MapSet` or `:gb_sets`.
* Ordered queues: `:queue`.
* Dense integer-indexed collections: `:array` or `:gb_trees` depending on access patterns.

## Avoid length/empty pitfalls

* Don’t do `length(list) > 0` (O(n)). Use `match?([_ | _], list)`.

## Prefer explicit map/struct access

* Required keys: `map.key` (raises early).
* Optional/dynamic: `map[:key]`.

## Normalize tuple returns early

Unify `{:ok, v}`/`{:error, r}` in helpers so `with` stays clean.

```elixir
with {:ok, bin} <- read_file(path),
     {:ok, data} <- decode(bin) do
  {:ok, data}
end
```

# 3) Concurrency and the BEAM

## Send less data between processes

Messages are copied. Extract only what’s needed:

```elixir
ip = conn.remote_ip
GenServer.cast(pid, {:report_ip, ip})
```

Avoid capturing big structs in closures for `Task`/`spawn`.

## Pick the right sharing primitive

* **ETS** for shared state with `read_concurrency: true`, `write_concurrency: true`.
* **:persistent_term** for read-mostly config. Updates are global and expensive; keep them rare.
* Avoid Agents/GenServers as “mutable variables.” They serialize work and allocate messages.

## Bound your parallelism

Use `Task.Supervisor` or `Task.async_stream/3` with `max_concurrency`, `timeout`, and `on_timeout: :kill_task` for back-pressure.

## Supervise long-running processes

All daemons under a supervisor. Use `handle_continue/2` for heavy init.

# 4) Micro-optimizations that actually matter

* **Avoid sub-binary pinning** when slicing tiny parts from giant binaries that will live long:

  ```elixir
  small = :binary.copy(binary_part(big, off, len))
  ```
* **Inline tiny wrappers** when they show in profiles:

  ```elixir
  @compile {:inline, my_wrap: 1}
  ```
* **Bitwise ops**: use `import Bitwise` for masks; match on bitstrings when parsing.
* **Tuples for fixed fields** you always read together; maps/structs for named, partial updates.
* **Module attributes for constants**:

  ```elixir
  @sec5 5 * 60
  now + @sec5
  ```

# 5) API design: non-raising and bang variants

Expose tuple APIs; layer `!` on top for scripts/tests.

```elixir
def fetch(name), do: Agent.get(name, & &1) |> ok_or(:not_found)

def fetch!(name) do
  case fetch(name) do
    {:ok, v} -> v
    {:error, r} -> raise ArgumentError, "fetch failed: #{inspect(r)}"
  end
end
```

Use `!` sparingly in application code; it’s fine in tests, scripts, and CLIs.

# 6) Elixir ↔ Erlang tips

* Reach for optimized Erlang modules when needed:

  * `:binary`, `:crypto`, `:zlib`, `:ets`, `:dets`, `:digraph`, `:unicode`.
* Prefer boolean operators `and/or/not` when operands must be booleans. Erlang does not have “truthiness”; atoms like `:undefined` are truthy in Elixir’s `&&/||`.
* Avoid dynamic atom creation. Map strings explicitly or use `String.to_existing_atom/1` after you ensure atoms exist.
* Use `:erlang.system_time/1` with `System.convert_time_unit/3` for cheap timing.

# 11) Anti-patterns to avoid (short list)

**Performance killers**

* `list ++ [x]` in loops.
* String concatenation in loops instead of iodata.
* Passing whole structs in messages or closures.
* Organizing “business logic” behind a GenServer when no shared mutable state is needed.

**Correctness/clarity**

* Complex `with ... else` that mixes unrelated errors. Normalize at the leaf.
* Accessing optional map keys with `map.key` or required keys with `map[:key]`.
* Non-assertive matching like catching `_` in `case` for function results that have more states.
* Booleans where atoms or tagged tuples model states better.
* Long parameter lists instead of grouping into maps/structs.
* Using global app config to steer library behavior per call; accept options instead.
* Namespace trespassing in libraries; always prefix modules with your lib’s root.

# 8) Practical checklists

## For list processing

* Prepend + `Enum.reverse/1`.
* Prefer `Enum.reduce/3` with accumulator shape you need at the end.
* If you must concat repeatedly, batch into chunks then concat once.

## For text/binaries

* Emit iodata from functions.
* Parse with bitstring matching.
* Avoid building giant strings for logging; let Logger handle formatting lazily.

## For services

* Cache hot lookups in ETS, not a GenServer state.
* Make background workers fetch arguments by ID to avoid copying payloads.

# 9) Minimal examples

**Good:**

```elixir
def filter_active(ids, fetch_fun) do
  ids
  |> Task.async_stream(fn id -> {id, fetch_fun.(id)} end,
       max_concurrency: System.schedulers_online(), timeout: 5_000)
  |> Stream.flat_map(fn
       {:ok, {id, %{active?: true}}} -> [id]
       _ -> []
     end)
  |> Enum.to_list()
end
```

**Bad:**

```elixir
def filter_active(ids, fetch_fun, pid) do
  Enum.reduce(ids, [], fn id, acc ->
    GenServer.call(pid, {:fetch, id, fetch_fun}) ++ acc  # copies, sync bottleneck, ++
  end)
end
```


## Formatting

* Use tabs consistently. Prefer soft tabs of 2 spaces.
* Use Unix line endings. Be consistent across files.
* No trailing whitespace.
* End every file with a newline.
* Keep lines under ~80 chars when practical.

## Whitespace & Operators

* Put spaces around operators and after commas.
* No spaces after `(` `[` `{` or before `)` `]` `}`.

```elixir
# preferred
Helper.format({1, true, 2}, :my_atom)

# also okay if consistent
Helper.format( { 1, true, 2 }, :my_atom )
```

## Statements

* Do not separate expressions with `;`.

```elixir
# preferred
IO.puts("Waiting for:")
IO.inspect(object)

# not okay
IO.puts("Waiting for:"); IO.inspect(object)
```

## Negation

* No space after `!`.

```elixir
denied = !allowed?
# not okay: denied = ! allowed?
```

## Function Grouping & Vertical Space

* Group same-name functions with different arities together. No blank lines between them.
* Use blank lines to separate different functions/sections.

```elixir
defp find_properties(source_file, config) do
  {property_for(source_file, config), source_file}
end
defp property_for(source_file, _config) do
  Enum.map(lines, &tabs_or_spaces/1)
end
```

* Use vertical space, clear names, and parentheses for readability.

## Pipelines

* Prefer starting pipelines with a value, not a function call.

```elixir
# preferred
username
|> String.trim()
|> String.downcase()

# also okay
String.trim(username)
|> String.downcase()
```

## Assignments spanning multiple lines

* Break after `=` and indent the value.

```elixir
# preferred
result =
  lines
  |> Enum.map(&tabs_or_spaces/1)
  |> Enum.uniq()

# also okay
result = lines
         |> Enum.map(&tabs_or_spaces/1)
         |> Enum.uniq()
```

## Numeric Literals

* Use underscores in large numbers.

```elixir
num = 10_000_000
# not okay: 10000000
```

## Definitions and Calls

* Use parentheses with `def/defp/defmacro` when params exist. Omit for zero-arity.

```elixir
def time do
  :ok
end
def convert(x, y) do
  x + y
end
```

* Prefer parentheses when calling functions that take parameters.

```elixir
Enum.reduce(1..100, 0, &(&1 + &2))
Enum.reduce(1..100, 0, fn x, acc -> x + acc end)

# also okay if consistent
Enum.reduce 1..100, 0, & &1 + &2
Enum.reduce 1..100, 0, fn x, acc -> x + acc end
```

## Macros & Conditionals

* Prefer no parentheses for macros like `use`.

```elixir
defmodule MyApp.Service.TwitterAPI do
  use MyApp.Service, social: true
  alias MyApp.Service.Helper, as: H
end
```

* Do not wrap `if`/`unless` conditions in parentheses.

```elixir
if valid?(username) do
  :ok
end
# not okay: if( valid?(username) ) do ...
```

## Naming

* Modules: `CamelCase`, keep acronyms uppercase (`HTTP`, `XML`).

```elixir
defmodule MyApp.HTTPService do
end
```

* Attributes, functions, macros, variables: `snake_case`.

```elixir
@some_setting :my_value
def my_function(param_value), do: :ok
```

## Exceptions

* Use a common prefix or suffix. Suffix `Error` is common.

```elixir
defmodule HTTPRequestError do
  defexception [:message]
end
```

## Predicates and Guards

* Predicate functions return booleans and end with `?`.

```elixir
def valid?(username), do: true
# not okay: def is_valid?(...), defmacro valid?(...)
```

* Guard-safe macros: prefix `is_`, do not end with `?`.

```elixir
defmacro is_valid(username), do: quote(do: true)
```

## Sigils

* Use sigils only when they improve clarity; do not be dogmatic.

```elixir
legend = "single quote ('), double quote (\")"
html = ~S(<a href="http://example.com">Home</a>)
```

## Regular Expressions

* Prefer `~r//`. Switch delimiters if `/` becomes noisy.

```elixir
regex = ~r/\d+/
regex = ~r{http://example.com/path/(.+)\.html}
# Note: ^ and $ match line start/end. Use \A and \z for whole string.
```

## Documentation

* Document modules/functions or mark with `@moduledoc false` / `@doc false`.
* Use ExDoc.
* Style: empty line after `@moduledoc`. No empty line between `@doc` and def.

```elixir
defmodule MyApp.HTTPService do
  @moduledoc false

  @doc "Sends a POST request to the given `url`."
  def post(url), do: :ok
end
```

* Comments are fine for context. Do not explain bad code with comments; fix the code.

## Refactoring Rules

* Max one level of nested `if`/`unless`/`case`. Split logic across functions.

```elixir
defp perform_task(true, hash, config) do
  hash |> Map.get(:action) |> perform_action(config)
end
```

## `unless`

* Never use `unless` with `else`. Rewrite as `if` with positive branch first.
* Never use `unless` with a negated condition. Rewrite as `if`.

## Module Reference

* Use `__MODULE__` when referencing the current module.

## Design Notes

* Use `FIXME:` for known bugs and `TODO:` for planned changes.

```elixir
# FIXME: this breaks for x > 1000
# TODO: rename into something clearer
```

## Aliases

* Alias used modules to make dependencies obvious. Prefer explicit `alias` blocks, except for well-known stdlib modules.

```elixir
defmodule Test do
  alias MyApp.External.TwitterAPI
  def something, do: TwitterAPI.search(...)
end
```

---
