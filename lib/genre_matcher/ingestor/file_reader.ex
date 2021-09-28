defmodule GenreMatcher.Ingestor.FileReader do
  require Logger 
  use GenStage, restart: :transient, shutdown: 10_000

  @behaviour Broadway.Acknowledger

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(%{filename: filename}) do
    {:producer, %{stream: File.stream!(filename), state: 0}}
  end

  @impl true
  def handle_demand(demand, %{stream: stream, state: state}) do
    to_dispatch =
      stream
      |> Stream.drop(state)
      |> Enum.take(demand)

    {:noreply, to_dispatch, %{stream: stream, state: state + demand}}
  end

  @impl Broadway.Acknowledger
  def ack(_, _, []), do: :ok

  @impl Broadway.Acknowledger
  def ack(term, _successful, failed) do
    Logger.critical("The Following Jobs Dispatched to Consumer with #{term} Failed")
    Logger.critical(failed)
    :ok
  end
end
