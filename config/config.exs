import Config

# Enable info logging to see encryption details
config :logger,
  level: :info

config :ex_wapp, :signal_impl, :native

config :logger, :console, format: "$time [$level] $message\n"
