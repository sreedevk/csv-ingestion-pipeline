defmodule GenreMatcher.Repo do
  use Ecto.Repo,
    otp_app: :genre_matcher,
    adapter: Ecto.Adapters.Postgres
end
