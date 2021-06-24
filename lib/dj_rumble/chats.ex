defmodule DjRumble.Chats do
  @moduledoc """
  Responsible for managing Chat processes
  """
  alias DjRumble.Chats.Supervisor

  defdelegate child_spec(init_arg), to: Supervisor
end
