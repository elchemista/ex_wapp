# Declares `@type t :: %__MODULE__{}` on every generated protobuf message module.
#
# protox does not emit a type for the structs it generates, which leaves callers
# with no good way to write specs: `Module.t()` is an unknown type to dialyzer,
# and inlining `%Module{}` in a `@spec` trips credo's SpecWithStruct check.
# Declaring the type here — as part of generation, never by hand-editing
# lib/ex_wapp/wa_proto — keeps both tools happy across regenerations.
#
# Enum modules are skipped: protox gives them an empty `defstruct []`, but their
# runtime representation is an atom, so a struct type would be a lie.
#
# Usage: elixir scripts/add_proto_typespecs.exs <generated-dir>

defmodule AddProtoTypespecs do
  @typespec "  @type t :: %__MODULE__{}"

  def run([dir]) do
    files = Path.wildcard(Path.join(dir, "*.ex"))

    if files == [] do
      abort("no .ex files found in #{dir}")
    end

    tally =
      Enum.reduce(files, %{added: 0, present: 0, enum: 0}, fn file, tally ->
        case annotate(File.read!(file)) do
          {:ok, contents} ->
            File.write!(file, contents)
            Map.update!(tally, :added, &(&1 + 1))

          {:skip, reason} ->
            Map.update!(tally, reason, &(&1 + 1))
        end
      end)

    IO.puts(
      "typespecs: #{tally.added} added, #{tally.present} already present, " <>
        "#{tally.enum} enum modules skipped"
    )
  end

  def run(_argv), do: abort("usage: elixir scripts/add_proto_typespecs.exs <generated-dir>")

  defp annotate(contents) do
    cond do
      String.contains?(contents, @typespec) -> {:skip, :present}
      not message_module?(contents) -> {:skip, :enum}
      true -> insert_typespec(contents)
    end
  end

  # A message module has at least one field; enum modules get `defstruct []`.
  defp message_module?(contents), do: Regex.match?(~r/^  defstruct (?!\[\]$)/m, contents)

  # The struct must already exist where the type is expanded, so the type goes at
  # the end of the module body: generated files hold exactly one module and close
  # it with a bare `end`.
  defp insert_typespec(contents) do
    case Regex.run(~r/\nend\n\z/, contents) do
      nil -> abort("unexpected module tail; generator layout changed?")
      _ -> {:ok, String.replace_suffix(contents, "\nend\n", "\n\n#{@typespec}\nend\n")}
    end
  end

  defp abort(message) do
    IO.puts(:stderr, "add_proto_typespecs: #{message}")
    System.halt(1)
  end
end

AddProtoTypespecs.run(System.argv())
