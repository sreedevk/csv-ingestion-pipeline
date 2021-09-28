defmodule GenreMatcher.Utils.ApplicationRegistry do
  def init do
    :ets.new(:application_registry, [:named_table])
  end

  def insert(key, value) do
    :ets.insert(:application_registry, {key, value})
  end

  def lookup(key) do
    :ets.lookup(:application_registry, key)
  end
end
