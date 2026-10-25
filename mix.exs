defmodule ExWapp.MixProject do
  use Mix.Project

  @version "0.1.5"
  @author "Yuriy Zhar"
  @source_url "https://github.com/elchemista/ex_wapp"
  @author_url "https://github.com/elchemista"
  @issues_url "#{@source_url}/issues"

  def project do
    [
      app: :ex_wapp,
      name: "ExWapp",
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "Runtime-neutral WhatsApp Web client library for Elixir",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),
      test_coverage: test_coverage(),
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs", list_unused_filters: true],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :inets, :ssl],
      mod: {ExWapp.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:ed25519, "~> 1.5.2"},
      # Generated wire modules call Protox encoders/decoders at runtime.
      {:protox, "~> 2.1"},
      {:phoenix_pubsub, "~> 2.4.1"},
      {:websockex, "~> 0.5.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: [
        ".formatter.exs",
        "examples",
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "docs",
        "LICENSE"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "Author" => @author_url,
        "GitHub" => @source_url,
        "Documentation" => "https://hexdocs.pm/ex_wapp",
        "Issue tracker" => @issues_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      authors: [@author],
      canonical: "https://hexdocs.pm/ex_wapp",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/architecture.md",
        "docs/design-decisions.md",
        "docs/protocol-flow.md",
        "docs/protocol-reference.md",
        "docs/strengths-and-limitations.md"
      ],
      skip_undefined_reference_warnings_on: &skip_protocol_doc_warning?/1,
      groups_for_modules: [
        "Public client API": [
          ExWapp,
          ExWapp.Call,
          ExWapp.Chat,
          ExWapp.Client,
          ExWapp.Contact,
          ExWapp.Event,
          ExWapp.JSON,
          ExWapp.Media,
          ExWapp.Message
        ],
        "Extension points": [
          ExWapp.Client.Transport,
          ExWapp.Events,
          ExWapp.JSON.Library,
          ExWapp.QR.Renderer,
          ExWapp.Telemetry,
          ExWapp.Telemetry.Adapter,
          ExWapp.Store
        ]
      ]
    ]
  end

  defp skip_protocol_doc_warning?(reference) when is_binary(reference) do
    reference in ["docs/protocol-flow.md", "docs/protocol-reference.md"] or
      String.starts_with?(reference, "lib/ex_wapp/")
  end

  defp skip_protocol_doc_warning?(_reference), do: false

  # Protox output is checked by schema, wire-compatibility, and round-trip
  # tests. Counting each generated module as application code makes the line
  # coverage number describe the schema size instead of ExWapp's maintained
  # implementation.
  defp test_coverage do
    [
      ignore_modules: [~r/^W[A-Z]/],
      summary: [threshold: 90]
    ]
  end
end
