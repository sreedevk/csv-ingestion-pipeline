defmodule GenreMatcher.Matcher.Pipeline do
  alias Broadway.Message
  use Broadway

  @max_attempts 5

  def start_link(opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          OffBroadwayRedisStream.Producer,
          [redis_client_opts: [host: "localhost", port: 6969], stream: opts.stream_name, consumer_name: hostname()]},
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
  def handle_message(_, message, _) do
    IO.inspect(message, label: "Got message")
    tag_batcher_on_message(message)
  end

  defp tag_batcher_on_message(message) do
    message
    |> Message.put_batcher(:matcher_batch)
    |> Message.put_batch_key(message.data.genre)
  end


  def handle_failed(messages, _) do
    for message <- messages do
      if message.metadata.attempt < @max_attempts do
        Broadway.Message.configure_ack(message, retry: true)
      else
        [id, _] = message.data
        IO.inspect(id, label: "Dropping")
      end
    end
  end

  defp hostname do
    {:ok, host} = :inet.gethostname()
    to_string(host)
  end
end
