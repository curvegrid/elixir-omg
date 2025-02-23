# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :omg_child_chain_rpc,
  child_chain_api_module: OMG.ChildChain

# Configures the endpoint
config :omg_child_chain_rpc, OMG.ChildChainRPC.Web.Endpoint,
  render_errors: [view: OMG.ChildChainRPC.Web.Views.Error, accepts: ~w(json)],
  instrumenters: [SpandexPhoenix.Instrumenter],
  enable_cors: true

# Use Poison for JSON parsing in Phoenix
config :phoenix,
  json_library: Jason,
  serve_endpoints: true,
  persistent: true

config :omg_child_chain_rpc, OMG.ChildChainRPC.Tracer,
  service: :web,
  adapter: SpandexDatadog.Adapter,
  disabled?: {:system, "DD_DISABLED", false, {String, :to_existing_atom}},
  env: {:system, "APP_ENV"},
  type: :web

config :spandex_phoenix, tracer: OMG.ChildChainRPC.Tracer

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
