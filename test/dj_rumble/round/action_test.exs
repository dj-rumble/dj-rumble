defmodule DjRumble.Round.ActionTest do
  @moduledoc """
  Action tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  describe "Action" do
    alias DjRumble.Rounds.{Action, ActionsDeck, Round}

    test "apply/2 with Action.CountTime returns an elapsed round time" do
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

    test "apply/2 with %Action.Score{type: :positive} returns a positive score" do
      type = :positive
      amount = 1
      at_time = 5
      action = %Action.Score{type: type, amount: amount, at_time: at_time}
      round = %Round.InProgress{score: {0, 0}}
      assert Action.apply(action, round) == {1, 0}
    end

    test "apply/2 with %Action.Score{type: :negative} returns a negative score" do
      type = :negative
      amount = 1
      at_time = 5
      action = %Action.Score{type: type, amount: amount, at_time: at_time}
      round = %Round.InProgress{score: {0, 0}}
      assert Action.apply(action, round) == {0, 1}
    end
  end
end
