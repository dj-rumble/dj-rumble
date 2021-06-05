defmodule DjRumble.Rounds.Log do
  @moduledoc """
  Responsible for defining a Round log
  """
  import Algae

  alias DjRumble.Rounds

  defdata do
    actions :: [Rounds.Action.t()] \\ []
    narrations :: [String.t()] \\ []
  end

  def narrate(%Rounds.Log{narrations: narrations}) do
    narrations
  end

  def append(%Rounds.Log{} = log, action) do
    %Rounds.Log{
      log
      | actions: log.actions ++ [action],
        narrations: log.narrations ++ [narrate_action(action)]
    }
  end

  defp narrate_action(%Rounds.Action.CountTime{} = action) do
    count_time_narration(Enum.random(1..3), action)
  end

  defp count_time_narration(_, action) do
    [
      "Elapsed time: ",
      action.time
    ]
  end
end
