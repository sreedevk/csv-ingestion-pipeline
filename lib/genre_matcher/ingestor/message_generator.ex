defmodule GenreMatcher.Ingestor.MessageGenerator do
  alias Broadway.Message

  def generate(event, _opts) do
    %Message{
      data: %{
        "type" => "movie.csv_record",
        "object" => %{ "movie" => format_event(event) },
        "batch_key" => fetch_batch_key(event)
      },
      acknowledger: {GenreMatcher.Ingestor.Pipeline, :ack_id, :ack_data}
    }
  end

  defp format_event(event) do
    String.split(event, ",")
  end

  defp fetch_batch_key(event) do
    {:ok, batch_key} = Enum.fetch(String.split(event, ","), 4)
    batch_key
  end
end
