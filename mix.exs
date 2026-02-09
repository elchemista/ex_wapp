defmodule ExWapp.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_wapp,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :dev,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {ExWapp.Application, []}
    ]
  end

  defp deps do
    [
      {:websockex, "~> 0.4"},
      {:ed25519, "~> 1.4"},
      {:protox, "~> 1.7"},
      {:telemetry, "~> 1.2"},
      {:qr_code, "~> 3.2.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end
end
