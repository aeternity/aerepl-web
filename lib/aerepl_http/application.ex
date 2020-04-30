defmodule AereplHttp.Application do
  use Application

  def start(_type, _args) do
    children = [
      AereplHttpWeb.Endpoint,
      {StateKeeper, %{}}
    ]

    opts = [strategy: :one_for_one, name: AereplHttp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    AereplHttpWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
