defmodule GenreMatcher.Ingestor.FileReader do
  require Logger 
  use GenStage

  alias GenreMatcher.Utils.ApplicationRegistry, as: AppReg
  alias NimbleCSV.RFC4180, as: CSV

  @behaviour Broadway.Acknowledger

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(%{filename: filename, input_stream_name: redis_stream_name}) do
    AppReg.insert("input_stream_name", redis_stream_name)
    {:producer, %{
        stream: File.stream!(Path.join(System.get_env("APP_ROOT"), filename)),
        state: 0
     }}
  end

  @impl true
  def handle_demand(demand, %{stream: stream, state: state}) do
    to_dispatch =
      stream
      |> Stream.drop(state)
      |> CSV.parse_stream(skip_headers: false)
      |> Enum.take(demand)

    {:noreply, to_dispatch, %{stream: stream, state: state + demand}}
  end

  @impl Broadway.Acknowledger
  def ack(term, _successful, failed) do
    Logger.critical("The Following Jobs Dispatched to Consumer with #{term} Failed")
    Logger.critical(failed)
    :ok
  end
end
