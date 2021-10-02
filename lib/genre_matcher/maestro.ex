defmodule GenreMatcher.Maestro do
  use DynamicSupervisor

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # spec = {GenreMatcher.Ingestor.Pipeline, opts}
  def start_child(spec) do
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(opts) do
    children = [
      # ,
      # {GenreMatcher.Matcher.Pipeline, opts}
    ]
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
