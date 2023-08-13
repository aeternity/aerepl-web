defmodule AereplServer.SessionData do
  @moduledoc """
  User session data.
  """

  defstruct id: nil,
    client_id: nil,
    start: nil,
    last_interaction: nil,
    timeout: nil,

  def new(client_id) do
    struct(__MODULE__, [
          id: UUID.uuid4(),
          client_id: client_id,
          start: DateTime.utc_now(),
          last_interaction: DateTime.utc_now(),
          timeout: Time.new(0, 0, 10)
        ])
  end

  def touch(session) do
    %{session | last_interaction: DateTime.utc_now()}
  end

  def is_timeout(session) do
    timeout_sec = Time.to_seconds_after_midnight(session.timeout)
    deadline = DateTime.add(session.last_interaction, timeout_sec, :second)
    now = DateTime.utc_now()
    DateTime.before?(deadline, now)
  end
end
