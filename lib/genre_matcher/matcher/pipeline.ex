defmodule GenreMatcher.Matcher.Pipeline do
  alias Broadway.Message
  alias GenreMatcher.Matcher.Wiki
  alias GenreMatcher.Utils.ApplicationRegistry, as: AppReg
  alias GenreMatcher.Utils.RedisStream

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
    batch_insert_redis(batch)
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

  defp batch_insert_redis(batch) do
    update_summaries(batch)
    stream = AppReg.lookup("output_stream_name")
    entries = Enum.map(batch, fn entry ->
      case RedisStream.xadd(stream, format_data_for_redis_stream(entry.data)) do
        {:ok, _result} -> entry
        {:error, errmsg} -> Message.failed(entry, errmsg.message)
      end
    end)
    entries
  end

  defp update_summaries(batch) do
    batch
    |> Enum.group_by(fn message -> message.data.genre end)
    |> Enum.map(fn {key, value} = dildo ->
      parsed_key = List.first(String.split(key, "|"))
      previous_count = Redix.command!(:redix, ["HGET", "genre_matching_summary", parsed_key]) || "0"
      Redix.command(:redix, ["HSET", "genre_matching_summary", parsed_key, Enum.count(value) + String.to_integer(previous_count)])
    end)
  end

  defp format_data_for_redis_stream(map_format_data) do
    [
      "id", map_format_data.id,
      "user_id", map_format_data.user_id,
      "name", map_format_data.name,
      "rating", map_format_data.rating,
      "genre", map_format_data.genre,
      "genre_info", map_format_data.genre_desc
    ]
  end
end
