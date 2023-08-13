defmodule AereplServerWeb.PageController do
  use AereplServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
