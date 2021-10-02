defmodule GenreMatcher.Ingestor.MessageGenerator do
  alias Broadway.Message
  alias NimbleCSV.RFC4180, as: CSV

  def generate(event, _opts) do
    %Message{
      data: %{
        "type" => "movie.csv_record",
        "object" => %{
          "movie" => format_event(parse_event(event))
        },
        "batch_key" => fetch_batch_key(event)
      },
      acknowledger: {GenreMatcher.Ingestor.Pipeline, :ack_id, :ack_data}
    }
  end

  defp parse_event(event) do
    CSV.parse_string(event)
  end

  defp format_event(parsed_record) do
    [id, user_id, name, rating, genre] = parsed_record
    Jason.encode(
      %{
        id: id,
        user_id: user_id,
        name: name,
        rating: rating,
        genre: genre
      }
    )
  end

  defp fetch_batch_key(event) do
    case Enum.fetch(String.split(event, ","), 4) do
      {:ok, batch_key} -> batch_key
      _ -> :default
    end
  end
end
