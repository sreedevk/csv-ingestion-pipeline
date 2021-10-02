defmodule GenreMatcher.Utils.RedisStream do
  def xadd(stream_name, key, value) do
    Redix.command(:redix, ["XADD", stream_name, "*", key, value])
  end

  def batch_xadd(stream_name, list) do
    for { key, value } <- list do
      xadd(stream_name, key, value)
    end
  end

  def xrange(stream_name, start_index, end_index) do
    Redix.command(:redix, ["XRANGE", stream_name, start_index, end_index])
  end

  def xrange(stream_name, start_index, end_index, count) do
    Redix.command(:redix, ["XRANGE", stream_name, start_index, end_index, "COUNT", count])
  end 

  def xack(stream_name, consumer_group, message_id) do
    Redix.command(:redix, ["XACK", stream_name, consumer_group, message_id])
  end
end
