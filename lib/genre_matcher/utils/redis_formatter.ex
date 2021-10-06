defmodule GenreMatcher.Utils.RedisFormatter do
  def fetch_hash(hash_var) do
    {:ok, result} = format_hash(Redix.command(:redix, ["HGETALL", hash_var]))
    result
  end

  defp format_hash(result) do
    result
    |> Enum.chunk_every(2)
    |> Enum.reduce(%{}, fn [key, value], mem ->
      Map.update(mem, %{key => value})
    end)
  end
end
