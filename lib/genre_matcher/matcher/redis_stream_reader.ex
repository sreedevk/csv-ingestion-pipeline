defmodule GenreMatcher.Matcher.RedisStreamReader do
  use GenStage
  alias GenreMatcher.Utils.RedisStream
  alias GenreMatcher.Utils.ApplicationRegistry, as: AppReg

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    AppReg.insert("output_stream_name", opts.output_stream_name)
    {:producer, %{state: 0}}
  end

  def handle_demand(demand, %{state: state}) do
    {:ok, to_dispatch} = RedisStream.xrange(AppReg.lookup("input_stream_name"), state, "+", demand)
    {:noreply, to_dispatch, %{state: fetch_stamp(List.last(to_dispatch))}}
  end

  defp fetch_stamp(stream_message) do
    List.first(stream_message)
  end
end
