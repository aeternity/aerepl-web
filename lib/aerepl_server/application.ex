defmodule AereplServer.Application do
  use Application

  def load_paths() do
    # TODO: wtf fix this
    {:ok, cwd} = File.cwd
    for path <- Path.wildcard(cwd <> "/deps/aerepl/_build/prod/rel/aerepl/lib/*/ebin"),
      do: :true = :code.add_path(String.to_charlist(path)) #Code.append_path(path)

    # :ok = Application.load(:syntax_tools)
    # :ok = Application.load(:goldrush)
    # :ok = Application.load(:lager)

    :ok = Application.load(:aechannel)
    :ok = Application.load(:aecontract)
    :ok = Application.load(:aecore)
    :ok = Application.load(:aefate)
    :ok = Application.load(:aens)
    :ok = Application.load(:aeoracle)
    :ok = Application.load(:aeprimop)
    :ok = Application.load(:aetx)
    :ok = Application.load(:aeutils)
    # :ok = Application.load(:setup)

    # :ok = Application.start(:goldrush)
    # :ok = Application.start(:lager)
    # :ok = Application.start(:aechannel)
    # :ok = Application.start(:aecontract)
    # :ok = Application.start(:aecore)
    # :ok = Application.start(:aefate)
    # :ok = Application.start(:aens)
    # :ok = Application.start(:aeoracle)
    # :ok = Application.start(:aeprimop)
    # :ok = Application.start(:aetx)
    # :ok = Application.start(:aeutils)
    # :ok = Application.start(:setup)

    :ok = Application.load(:aerepl)
    {:ok, _} = Application.ensure_all_started(:aerepl)

    IO.inspect("************************ " <> Application.app_dir(:aerepl))

    :ok = Application.ensure_started(:aerepl)

    IO.inspect(:code.get_path)
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
