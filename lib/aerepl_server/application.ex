defmodule AereplServer.Application do
  use Application

  def load_paths() do
    for path <- Path.wildcard("deps/aerepl/_build/prod/rel/aerepl/lib/*/ebin"),
      do: Code.append_path(path)
  end

  def start(_type, _args) do
    load_paths()

    children = [
      {Phoenix.PubSub, [name: AereplServer.PubSub, adapter: Phoenix.PubSub.PG2]},
      AereplServerWeb.Endpoint,
      AereplServer.AereplSupervisor,
    ]

    opts = [
      strategy: :one_for_one,
      name: AereplServer.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    AereplServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
