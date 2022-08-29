defmodule AereplHttp.Application do
  use Application

  def load_paths() do
    for path <- Path.wildcard("deps/aerepl/_build/prod/lib/*/ebin"),
      do: Code.append_path(path)
  end

  def start(_type, _args) do
    children = [
      AereplHttpWeb.Endpoint,
      {Phoenix.PubSub, [name: AereplHttp.PubSub, adapter: Phoenix.PubSub.PG2]}
    ]

    load_paths()

    opts = [strategy: :one_for_one, name: AereplHttp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    AereplHttpWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
