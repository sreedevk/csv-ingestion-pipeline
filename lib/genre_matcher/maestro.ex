defmodule GenreMatcher.Maestro do
  alias GenreMatcher.Utils.ApplicationRegistry, as: AppReg
  use DynamicSupervisor

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # spec = {GenreMatcher.Ingestor.Pipeline, opts}
  def start_child(spec) do
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_all_children do
    Enum.map(
      DynamicSupervisor.which_children(__MODULE__),
      fn {_id, child_pid, type, _modules} ->
        if type == :worker do
          DynamicSupervisor.terminate_child(__MODULE__, child_pid)
        end
      end)
  end

  @impl true
  def init(opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
