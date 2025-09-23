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
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:websockex, "~> 0.4"},
      {:libsignal_protocol, "~> 0.1.1"},
      {:ed25519, "~> 1.4"},
      {:rustler, "~> 0.37.1", runtime: false},
      {:eqrcode, "~> 0.2.0", only: [:dev, :test], runtime: false},
      {:protox, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end
end
