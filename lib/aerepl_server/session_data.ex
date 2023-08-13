defmodule AereplServer.SessionData do
  @moduledoc """
  User session data.
  """

  defstruct id: nil,
    start: nil,
    last_interaction: nil

  def new() do
    struct(__MODULE__, [
          id: UUID.uuid4(),
          start: DateTime.utc_now(),
          last_interaction: DateTime.utc_now(),
        ])
  end

  def touch(session) do
    %{session | last_interaction: DateTime.utc_now()}
  end

end
