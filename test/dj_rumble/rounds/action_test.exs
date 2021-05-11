defmodule DjRumble.Rounds.ActionTest do
  @moduledoc """
  Action tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  describe "log" do
    alias DjRumble.Rounds.{Action, ActionsDeck, Round}

    test "apply/1 with Action.CountTime returns an elapsed round time" do
      action_time = 1
      elapsed_time = 5
      action = %Action.CountTime{time: action_time}
      round = %Round.InProgress{elapsed_time: elapsed_time}
      assert Action.apply(action, round) == elapsed_time + action_time
    end

    test "from_properties/1 returns a CountTime action" do
      properties = ActionsDeck.count_action_properties()
      assert Action.from_properties(properties) == %Action.CountTime{time: 1}
    end
  end
end
