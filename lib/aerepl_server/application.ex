defmodule AereplServer.Application do
  use Application

  def load_paths() do
    # TODO: wtf fix this
    {:ok, cwd} = File.cwd
    for path <- Path.wildcard(cwd <> "/deps/aerepl/_build/prod/rel/aerepl/lib/*/ebin/") do
      :true = :code.add_path(String.to_charlist(path))
    end

    :ok = Application.load(:aechannel)
    :ok = Application.load(:aecontract)
    :ok = Application.load(:aecore)
    :ok = Application.load(:aefate)
    :ok = Application.load(:aens)
    :ok = Application.load(:aeoracle)
    :ok = Application.load(:aeprimop)
    :ok = Application.load(:aetx)
    :ok = Application.load(:aeutils)

    for path <- Path.wildcard(cwd <> "/deps/aerepl/_build/prod/rel/aerepl/lib/*/ebin/") do
      :true = :code.add_path(String.to_charlist(path))
      for mod_file <- Path.wildcard(path <> "/*.beam") do
        mod = String.to_atom(Path.rootname(Path.basename(mod_file)))
        if :code.module_status(mod) != :loaded do
          try do
            :code.load_file(mod)
          rescue
            _ in RuntimeError ->
              IO.inspect({:module_not_loaded, mod})
          end
        end
      end
    end

    Application.ensure_all_started(:aerepl)
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
