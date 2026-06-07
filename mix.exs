defmodule ExWapp.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_wapp,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :dev,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :inets, :ssl],
      mod: {ExWapp.Application, []}
    ]
  end

  defp deps do
    [
      {:ed25519, "~> 1.4"},
      {:protox, "~> 1.7"},
      {:phoenix_pubsub, "~> 2.1"},
      {:telemetry, "~> 1.2"},
      {:websockex, "~> 0.4"},
      {:qr_code, "~> 3.2.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end
end
