defmodule GenreMatcher.Matcher.Wiki do
  @wiki_api_base_url "https://en.wikipedia.org/w/api.php"

  def search(term, opts \\ %{count: 1}) do
    case HTTPoison.get(@wiki_api_base_url, [], params: generate_query(term, opts)) do
      {:ok, resp} -> cache_search_results(term, resp.body)
      err_result -> err_result
    end
  end

  def search_cache(term) do
    case Redix.command(:redix, ["GET", "wiki:search:#{term}"]) do
      {:ok, nil} -> search(term)
      {:ok, result} -> result
      _ -> nil
    end
  end

  defp cache_search_results(term, result) do
    Redix.command(:redix, ["SET", "wiki:search:#{term}", result])
    result
  end

  defp generate_query(term, opts) do
    %{
      action: :query,
      format: :json,
      list: :search,
      utf8: 1,
      srsearch: term,
      srlimit: opts.count
    }
  end
end
