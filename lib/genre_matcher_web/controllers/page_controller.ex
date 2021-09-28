defmodule GenreMatcherWeb.PageController do
  use GenreMatcherWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
