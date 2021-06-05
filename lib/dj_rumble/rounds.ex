defmodule DjRumble.Rounds do
  @moduledoc """
  Responsible for managing Rounds
  """
  alias DjRumble.Rounds.Supervisor

  defdelegate child_spec(init_arg), to: Supervisor
end
