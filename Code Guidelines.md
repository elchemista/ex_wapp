# Elixir Code Guidelines

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