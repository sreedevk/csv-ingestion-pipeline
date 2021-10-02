defmodule GenreMatcher.Matcher.RedisStreamReader do
  use GenStage
  alias GenreMatcher.Utils.RedisStream

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    {:producer, %{state: 0, input_stream_name: opts.input_stream_name, output_stream_name: opts.output_stream_name}}
  end

  def handle_demand(demand, %{state: state, input_stream_name: input_stream_name, output_stream_name: output_stream_name}) do
    {:ok, to_dispatch} = RedisStream.xrange(input_stream_name, state, "+", demand)
    {:noreply, to_dispatch, %{state: fetch_stamp(List.last(to_dispatch)), input_stream_name: input_stream_name, output_stream_name: output_stream_name}}
  end

  defp fetch_stamp(stream_message) do
    List.first(stream_message)
  end
end
