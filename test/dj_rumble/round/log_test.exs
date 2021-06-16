defmodule DjRumble.Round.LogTest do
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

    test "append/2 with %Action.CountTime{} returns a log with a new action and a new narration" do
      %Log{actions: [], narrations: []} = log = Log.new()
      action_time = 1
      action = %Action.CountTime{time: action_time}

      %Log{actions: [^action], narrations: [["Elapsed time: ", ^action_time]]} =
        Log.append(log, action)
    end

    @tag :wip
    test "append/2 with %Action.Score{type: :positive} returns a log with a new action and a new upvoted narration" do
      %Log{actions: [], narrations: []} = log = Log.new()
      action_time = 1
      action = %Action.Score{type: :positive, at_time: action_time}

      %Log{actions: [^action], narrations: [["Scores positively at ", ^action_time]]} =
        Log.append(log, action)
    end

    @tag :wip
    test "append/2 with %Action.Score{type: :negative} returns a log with a new action and a new downvoted narration" do
      %Log{actions: [], narrations: []} = log = Log.new()
      action_time = 1
      action = %Action.Score{type: :negative, at_time: action_time}

      %Log{actions: [^action], narrations: [["Downvoted at ", ^action_time]]} =
        Log.append(log, action)
    end
  end
end
