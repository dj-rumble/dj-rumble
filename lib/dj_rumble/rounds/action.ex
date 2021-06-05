defmodule DjRumble.Rounds.Action do
  @moduledoc """
  Responsible for defining Round actions
  """
  import Algae

  alias DjRumble.Rounds.Action

  # Just placeholder actions for now
  defsum do
    defdata CountTime do
      time :: non_neg_integer() \\ 1
    end

    defdata Score do
      time :: non_neg_integer() \\ 1
    end
  end

  def apply(%Action.CountTime{time: time} = _action, round) do
    round.elapsed_time + time
  end

  def from_properties(properties) when is_map(properties) do
    case properties.kind do
      :count_time ->
        %Action.CountTime{
          time: properties.time
        }
    end
  end
end
