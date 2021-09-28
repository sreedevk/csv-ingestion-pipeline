# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :genre_matcher,
  ecto_repos: [GenreMatcher.Repo]

# Configures the endpoint
config :genre_matcher, GenreMatcherWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "59EHDgWhEAe+3T7L6RBZu0pc416G0yUsnLUNSmyP4PfOVguEeY03gl4phtYj55pJ",
  render_errors: [view: GenreMatcherWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GenreMatcher.PubSub,
  live_view: [signing_salt: "MgPs4Gde"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
