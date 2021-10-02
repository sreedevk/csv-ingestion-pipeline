defmodule GenreMatcher.Matcher.MessageGenerator do
  alias Broadway.Message

  def generate(event) do
    %Message{
      data: event,
      acknowledger: {GenreMatcher.Matcher.Pipeline, :ack_id, :ack_data}
    }
  end

  def ack(_ref, _succ, _fail), do: :ok
end
