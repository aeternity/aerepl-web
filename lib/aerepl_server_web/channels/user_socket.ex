defmodule AereplServerWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "repl_session:*", AereplServerWeb.ReplSessionChannel

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
