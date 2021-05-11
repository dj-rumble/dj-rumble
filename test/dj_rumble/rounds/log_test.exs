defmodule DjRumble.Rounds.LogTest do
  @moduledoc """
  Log tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  describe "log" do
    alias DjRumble.Rounds.{Action, Log}

    test "narrate/1 returns narrations" do
      narrations = ["Some", "Narration"]
      log = %Log{narrations: narrations}
      ["Some", "Narration"] = Log.narrate(log)
    end

    @tag wip: true
    test "append/2 returns a log with a new action and a new narration" do
      %Log{actions: [], narrations: []} = log = Log.new()
      action_time = 1
      action = %Action.CountTime{time: action_time}

      %Log{actions: [^action], narrations: [["Elapsed time: ", ^action_time]]} =
        Log.append(log, action)
    end
  end
end
