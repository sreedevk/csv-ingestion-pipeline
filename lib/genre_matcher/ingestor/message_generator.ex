defmodule GenreMatcher.Ingestor.MessageGenerator do
  require Logger
  alias Broadway.Message

  def generate(event, _opts) do
    %Message{
      data: %{
        type: "movie.csv_record",
        object: format_event(event),
        batch_key: fetch_batch_key(event)
      },
      acknowledger: {GenreMatcher.Ingestor.Pipeline, :ack_id, :ack_data}
    }
  end

  def ack(_ref, _succ, _fail), do: :ok

  defp format_event(parsed_record) do
    [id, user_id, name, rating, genre] = parsed_record
    %{id: id, user_id: user_id, name: name, rating: rating, genre: genre}
  end

  defp fetch_batch_key(event) do
    case Enum.fetch(event, 4) do
      {:ok, batch_key} -> batch_key
      _ -> :default
    end
  end
end
