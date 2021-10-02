defmodule GenreMatcher.Matcher.MessageGenerator do
  alias Broadway.Message

  def generate(event, _opts) do
    IO.inspect(event)
    %Message{
      data: format_data(event),
      acknowledger: {GenreMatcher.Matcher.Pipeline, :ack_id, :ack_data}
    }
  end

  def ack(_ref, _succ, _fail), do: :ok

  defp format_data(event) do
    List.last(event)
    |> Enum.chunk_every(2)
    |> Enum.reduce(%{}, fn [key, val], acc ->
      Map.merge(acc, %{String.to_atom(key) => val})
    end)
  end
end
