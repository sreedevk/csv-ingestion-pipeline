defmodule GenreMatcher.Utils.RedisStream do
  def xadd(stream_name, data) do
    Redix.command(:redix, ["XADD", stream_name, "*"] ++ data)
  end

  def xrange(stream_name, start_index, end_index) do
    Redix.command(:redix, ["XRANGE", stream_name, start_index, end_index])
  end

  def xrange(stream_name, start_index, end_index, count) do
    Redix.command(:redix, ["XRANGE", stream_name, start_index, end_index, "COUNT", count])
  end

  def xrange!(stream_name, start_index, end_index) do
    Redix.command!(:redix, ["XRANGE", stream_name, start_index, end_index])
  end

  def xrange!(stream_name, start_index, end_index, count) do
    Redix.command!(:redix, ["XRANGE", stream_name, start_index, end_index, "COUNT", count])
  end

  def xack(stream_name, consumer_group, message_id) do
    Redix.command(:redix, ["XACK", stream_name, consumer_group, message_id])
  end
end
