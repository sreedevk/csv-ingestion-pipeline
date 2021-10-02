defmodule GenreMatcher.Ingestor.FileReader do
  require Logger 
  use GenStage, restart: :transient, shutdown: 10_000

  alias GenreMatcher.Utils.ApplicationRegistry, as: AppReg

  @behaviour Broadway.Acknowledger

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(%{filename: filename, stream_name: redis_stream_name}) do
    AppReg.insert("redis_stream_name", redis_stream_name)
    {:producer, %{stream: File.stream!(filename), state: 0}}
  end

  @impl true
  def handle_demand(demand, %{stream: stream, state: state}) do
    to_dispatch =
      stream
      |> Stream.drop(state)
      |> Stream.filter(fn record -> String.match?(record, ~r/\w+\,\w+\,\w+\,\w+\,\w+/) end)
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
