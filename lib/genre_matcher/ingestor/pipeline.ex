defmodule GenreMatcher.Ingestor.Pipeline do
  use Broadway
  alias Broadway.{Message, BatchInfo}
  alias GenreMatcher.Repo

  # opts = %{filename: "produced.csv", stream_name: "ingestion_stream", stream_pid: #PID<1.2.3>}
  def start_link(opts) do
    Broadway.start_link(
      __MODULE__,
      name: __MODULE__,
      max_restarts: 3,
      context: :ingestion,
      producer: [
        module: {GenreMatcher.Ingestor.FileReader, opts},
        transformer: {GenreMatcher.Ingestor.MessageGenerator, :generate, opts}
      ],
      processors: [
        # FIRST PROCESSOR - CONVERTS BROADWAY MESSAGES INTO DATA STRINGS
        data_transformer: [
          min_demand: 80_000,
          max_demand: 100_000,
          concurrency: 2
        ],
        # SECOND PROCESSOR - CONVERTS DATA STRINGS INTO REDIX HASHMAPS
        data_tagger: [
          min_demand: 80_000,
          max_demand: 100_000,
          concurrency: 2
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
          concurrency: 2,
          batch_size: 100,
          batch_timeout: 500
        ]
      ]
    )
  end

  def ack(:ack_id, _successful, _failed), do: :ok

  @impl Broadway
  def handle_message(_processor, message, _context) do
    tag_batcher_on_message(message) 
  end

  # private functions - PROCESSOR
  defp tag_batcher_on_message(%Message{data: %{"type" => event}} = message) do
    case batching(event) do
      :default -> message
      {batcher, batch_key} when is_atom(batcher) -> 
        message
        |> Message.put_batcher(batcher)
        |> Message.put_batch_key(batch_key)
    end
  end

  defp batching("movie.csv_record") do
    { :dispatch_message, :movie }
  end

  defp batching(_), do: :default

  # functions - BATCHER
  def handle_batch(:dispatch_message, messages, _batch_info, _context) do
    batch_insert_redis(messages)
  end

  def handle_batch(_, messages, _), do: messages

  defp batch_insert_redis(batch) do
    case Redix.command(:redix, ["XADD", @stream_name, "*", "movies", entries]) do
      {:ok, _id} -> messages
      result -> batch_failed(messages, {:insert_all, schema, result})
    end
  end
end
