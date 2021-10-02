defmodule GenreMatcherWeb.PageController do
  use GenreMatcherWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def start_processing_pipelines(conn, _params) do
    GenreMatcher.Maestro.start_child({GenreMatcher.Ingestor.Pipeline, %{filename: "data/movies_dataset.csv", stream_name: "genre_matcher"}})
    GenreMatcher.Maestro.start_child({GenreMatcher.Matcher.Pipeline, %{input_stream_name: "genre_matcher", output_stream_name: "genre_processed"}})
    redirect(conn, to: "/")
  end

  def stop_processing_pipelines(conn, _params) do
    GenreMatcher.Maestro.terminate_all_children()
    redirect(conn, to: "/")
  end
end
