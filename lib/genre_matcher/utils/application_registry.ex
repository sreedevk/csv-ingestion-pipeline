defmodule GenreMatcher.Utils.ApplicationRegistry do
  def insert(key, value) do
    Redix.command!(:redix, ["SET", "application:#{key}", value])
  end

  def lookup(key) do
    Redix.command!(:redix, ["GET", "application:#{key}"])
  end
end
