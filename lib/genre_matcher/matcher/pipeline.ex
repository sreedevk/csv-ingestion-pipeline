defmodule GenreMatcher.Matcher.Pipeline do
  alias Broadway.Message
  alias GenreMatcher.Matcher.Wiki
  use Broadway

  @max_attempts 5

  def start_link(opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {GenreMatcher.Matcher.RedisStreamReader, opts},
        transformer: {GenreMatcher.Matcher.MessageGenerator, :generate, []}
      ],
      processors: [
        matcher: [
          min_demand: 5,
          max_demand: 1000,
          concurrency: 4
        ]
      ],
      batchers: [
        matcher_batch: [
          concurrency: 2,
          batch_size: 100_000,
          batch_timeout: 2_000
        ]
      ]
    )
  end

  def stop(reason), do: Broadway.stop(__MODULE__, reason)

  def ack(:ack_id, _successful, _failed), do: :ok

  @impl Broadway
  def handle_message(_processor, message, _context) do
    message
    |> tag_batcher_on_message()
    |> Message.update_data(fn evt_data ->
      Map.merge(
        evt_data,
        %{genre_desc: enhance_data(evt_data)}
      )
    end)
  end

  @impl Broadway
  def handle_batch(:matcher_batch, batch, _batch_info, _context) do
    Enum.map(batch, fn message ->
    end)
  end

  defp enhance_data(entry) do
    Wiki.search_cache(parse_genre_data(entry))
  end

  defp parse_genre_data(data) do
    List.first(String.split(data.genre, "|"))
  end

  defp tag_batcher_on_message(message) do
    message
    |> Message.put_batcher(:matcher_batch)
    |> Message.put_batch_key(message.data.genre)
  end
end
