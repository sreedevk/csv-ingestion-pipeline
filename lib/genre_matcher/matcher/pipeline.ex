defmodule GenreMatcher.Matcher.Pipeline do
  use Broadway

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {OffBroadwayRedisStream.Producer,
           [
             redis_client_opts: [host: "localhost"],
             stream: "genre-matcher",
             group: "processor-group",
             consumer_name: hostname()
           ]}
      ],
      processors: [
        default: [min_demand: 5, max_demand: 1000]
      ]
    )
  end

  def handle_message(_, message, _) do
    [_id, key_value_list] = message.data
    IO.inspect(key_value_list, label: "Got message")
    message
  end

  @max_attempts 5

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
