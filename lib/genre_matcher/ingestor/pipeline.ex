defmodule GenreMatcher.Ingestor.Pipeline do
  require Logger

  use Broadway
  alias Broadway.{Message, BatchInfo}
  alias GenreMatcher.Utils.RedisStream
  alias GenreMatcher.Utils.ApplicationRegistry, as: AppReg

  # opts = %{filename: "data/movies_dataset.csv", stream_name: "genre_matcher"}
  def start_link(opts) do
    Broadway.start_link(
      __MODULE__,
      name: __MODULE__,
      max_restarts: 3,
      shutdown: 10_000,
      producer: [
        module: {GenreMatcher.Ingestor.FileReader, opts},
        transformer: {GenreMatcher.Ingestor.MessageGenerator, :generate, []},
        concurrency: 2
      ],
      processors: [
        default: [
          min_demand: 10,
          max_demand: 50,
          concurrency: 5
        ]
      ],
      batchers: [
        # DEFAULT BATCHER
        default: [
          concurrency: 1,
          batch_size: 10,
          batch_timeout: 100,
        ],
        # BATCHER - BATCHES MOVIES BASED ON YEAR & INSERTS INTO REDIS
        dispatch_message: [
          concurrency: 5,
          batch_size: 50,
          batch_timeout: 500
        ]
      ]
    )
  end

  def stop(reason) do
    Broadway.stop(reason)
  end

  def ack(:ack_id, _successful, _failed), do: :ok

  @impl Broadway
  def handle_message(_processor, message, _context) do
    tag_batcher_on_message(message)
  end

  # private functions - PROCESSOR
  defp tag_batcher_on_message(%Message{data: %{type: event, batch_key: batch_key}} = message) do
    {batcher, batch_key} = batching(event, batch_key)
    message
    |> Message.put_batcher(batcher)
    |> Message.put_batch_key(batch_key)
  end

  defp batching("movie.csv_record", nil),       do: { :dispatch_message, :default }
  defp batching("movie.csv_record", batch_key), do: { :dispatch_message, batch_key }
  defp batching(_event, _key),                  do: { :default, :default }
  defp batching(_opts),                         do: { :default, :default }

  # functions - BATCHER
  @impl Broadway
  def handle_batch(:dispatch_message, messages, _batch_info, _context), do: batch_insert_redis(messages)
  def handle_batch(_, messages, _), do: messages

  defp batch_insert_redis(batch) do
    stream = AppReg.lookup("redis_stream_name")
    entries = Enum.map(batch, fn entry ->
      case RedisStream.xadd(stream, entry.data.object.id, Jason.encode!(entry.data.object)) do
        {:ok, result} -> entry
        {:error, errmsg} -> Message.failed(entry, errmsg.message)
      end
    end)
    entries
  end
end
