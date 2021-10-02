defmodule GenreMatcher.Maestro do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    children = [
      {GenreMatcher.Ingestor.Pipeline, opts},
      {GenreMatcher.Matcher.Pipeline, opts}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
