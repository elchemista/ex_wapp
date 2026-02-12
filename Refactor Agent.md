## Elixir refactoring guide

### Goals

* Improve readability first; performance changes only when profiling proves it matters.
* Make control flow obvious: fewer branches, less nesting, fewer “general” constructs.
* Make contracts explicit with typespecs (`@spec`, `@type`, `@callback`) so refactors stay safe.

---

## 1) Refactoring workflow

1. Lock behavior with tests (or add minimal tests around the change).
2. Refactor for clarity (reduce branching/nesting, normalize return shapes).
3. Add/adjust `@spec` (and `@type` / `@typep`) while the intent is fresh.
4. Run: `mix format`, `mix test`, `mix credo`, `mix dialyzer` (if you use Dialyzer).
5. If performance-related: profile (`mix profile.fprof/eprof`, Benchee) before and after.

---

## 2) Typespec rules (`@spec`) you should actually follow

### Required

* **Every public function (`def`) must have an `@spec`.**
* Every behaviour callback must have `@callback` (and implementations should match).
* If a function returns tagged tuples, the spec must show the exact shapes.

### Recommended

* Add `@type t()` for every struct module.
* Add `@type` for key domain concepts (IDs, money, status, etc.) instead of repeating `binary()` / `integer()`.
* Add `@spec` to private functions (`defp`) when:

  * they’re non-trivial,
  * they’re used in multiple places,
  * they return complex shapes (maps/structs/tuples),
  * or they are “leaf” helpers where errors originate.

### Practical examples

**Struct + types**

```elixir
defmodule MyApp.User do
  @type id :: pos_integer()

  @type t :: %__MODULE__{
          id: id(),
          email: String.t(),
          active?: boolean()
        }

  defstruct [:id, :email, active?: true]
end
```

**Public function with explicit error contract**

```elixir
@spec fetch_user(MyApp.User.id()) :: {:ok, MyApp.User.t()} | {:error, :not_found}
def fetch_user(id) do
  ...
end
```

**Option lists**

```elixir
@type opts :: [timeout: non_neg_integer(), retries: non_neg_integer()]

@spec run(job :: term(), opts()) :: :ok | {:error, term()}
def run(job, opts \\ []) do
  ...
end
```

**When specs need constraints**

```elixir
@spec take(binary(), non_neg_integer()) :: binary()
def take(bin, n) when is_binary(bin) and is_integer(n) and n >= 0 do
  binary_part(bin, 0, min(byte_size(bin), n))
end
```

### Avoid

* Specs that lie (worse than no spec).
* `term()` everywhere. Use it only at boundaries you truly can’t type yet.

---

## 3) Control-flow selection rules (do not over-engineer branching)

### Prefer function heads + guards (first choice)

Use multiple clauses when the decision is based on shape/type/pattern.

```elixir
@spec parse(binary()) :: {:ok, binary()} | {:error, :bad_prefix}
def parse(<<"OK:", rest::binary>>), do: {:ok, rest}
def parse(<<"ERR:", rest::binary>>), do: {:error, :bad_prefix}
def parse(_), do: {:error, :bad_prefix}
```

### Use `if` for a single boolean decision

**Do not** use `cond` for one condition.

Bad:

```elixir
cond do
  valid?(x) -> :ok
  true -> :error
end
```

Good:

```elixir
if valid?(x), do: :ok, else: :error
```

Also good (often clearer with early return):

```elixir
if not valid?(x), do: :error, else: :ok
```

### Use `case` when matching on a value/result

If you are branching on the *shape* of a value, `case` is appropriate.

```elixir
case Repo.get(User, id) do
  %User{} = user -> {:ok, user}
  nil -> {:error, :not_found}
end
```

### Use `with` only when chaining multiple steps

`with` is for **2+** dependent matches/guards.

**Do not** write `with` for one match.

Bad:

```elixir
with {:ok, user} <- fetch_user(id) do
  do_something(user)
end
```

Good:

```elixir
case fetch_user(id) do
  {:ok, user} -> do_something(user)
  {:error, reason} -> {:error, reason}
end
```

Or, if it’s a boolean check:

```elixir
if user = fetch_user!(id) do
  do_something(user)
end
```

### Use `cond` only for 2+ unrelated boolean branches

If conditions don’t share one matched value and there are multiple branches, `cond` is fine.

```elixir
cond do
  is_nil(x) -> {:error, :missing}
  x < 0 -> {:error, :negative}
  true -> {:ok, x}
end
```

---

## 4) Normalize return shapes early (keeps `with` and callers clean)

* Prefer `{:ok, value} | {:error, reason}` for operations that can fail.
* Convert odd shapes at the edges so your “core” logic stays uniform.

```elixir
@spec decode_file(Path.t()) :: {:ok, map()} | {:error, term()}
def decode_file(path) do
  with {:ok, bin} <- File.read(path),
       {:ok, data} <- decode(bin) do
    {:ok, data}
  end
end
```

Avoid `with ... else` that mixes unrelated error meanings. Fix at the leaf.

---

## 5) Refactoring rules that reduce nesting

* Max one level of nested `if`/`case` inside a function body. Split into helpers.
* Use guard clauses / early returns to avoid “pyramid code”.
* Prefer extracting a well-named helper over adding one more branch.

---

## 6) Data and performance rules (only apply when relevant)

### Lists

* Prepend in loops: `[x | acc]`, reverse once at the end.
* Avoid `list ++ [x]` in loops (O(n)).

### Text/binaries

* Use iodata for assembly, avoid `<>` in loops.
* Prefer binary pattern matching over repeated `String.*` ops on binaries.

### Concurrency

* Don’t hide business logic behind GenServers unless you need shared mutable state.
* Don’t send big structs in messages; send IDs or minimal fields.

---

## 7) Formatting and code style (keep consistent)

* 2-space indentation, no trailing whitespace, newline at EOF.
* Spaces around operators, after commas.
* No `;`.
* No parentheses for `if` / `unless` conditions.
* No `unless ... else`. Rewrite as `if` with the positive branch first.

---

## 8) Quick anti-pattern list (remove these during refactors)

* `cond do <one condition> -> ...; true -> ... end` → use `if`.
* `with` with a single `<-` match → use `case` (or function heads).
* `case` that only checks a boolean → use `if`.
* Big `case` on shapes that could be function clauses → use multi-clause + guards.
* Inconsistent return tuples across helpers (forces messy callers and `with ... else`).

---

## 9) Checklist for a “good refactor” PR

* [ ] Public API functions have correct `@spec`.
* [ ] Struct modules define `@type t()`.
* [ ] `with` used only for 2+ chained matches.
* [ ] No one-branch `cond`.
* [ ] Branching moved into function heads where pattern matching applies.
* [ ] Return shapes normalized (`{:ok, _} | {:error, _}`) where appropriate.
* [ ] `mix format`, tests, and (if enabled) Dialyzer pass.
