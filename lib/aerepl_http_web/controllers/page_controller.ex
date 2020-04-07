defmodule AereplHttpWeb.PageController do
  use AereplHttpWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
