defmodule AereplHttp.AereplSupervisor do
  @moduledoc """
  Supervisor process for handling user sessions.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    children = [
      {Registry, name: AereplHttp.SessionRegistry, keys: :unique},
      {DynamicSupervisor, name: AereplHttp.SessionSupervisor,  strategy: :one_for_one},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
