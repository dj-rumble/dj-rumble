defmodule DjRumble.Rounds.RoundTest do
  @moduledoc """
  Round tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  describe "round" do
    alias DjRumble.Rounds.{Log, Round}

    test "schedule/1 returns a scheduled round" do
      time = 5

      %Round.Scheduled{elapsed_time: elapsed_time, time: ^time, score: score} =
        Round.schedule(time)

      assert elapsed_time == 0
      assert score == {0, 0}
    end

    test "start/1 returns a round that is in progress" do
      time = 5
      round = %Round.Scheduled{time: time}

      %Round.InProgress{time: ^time, elapsed_time: elapsed_time, score: score, log: log} =
        Round.start(round)

      assert elapsed_time == 0
      assert score == {0, 0}
      assert log == Log.new()
    end

    test "finish/1 returns a finished round" do
      time = 5
      round = %Round.InProgress{time: time}

      %Round.Finished{
        time: ^time,
        elapsed_time: elapsed_time,
        score: score,
        log: log,
        outcome: outcome
      } = Round.finish(round)

      assert elapsed_time == 0
      assert score == {0, 0}
      assert log == Log.new()
      assert outcome == :continue
    end

    test "narrate/1 returns a log from a round that is in progress" do
      time = 5
      round = %Round.InProgress{time: time}
      assert Round.narrate(round) == []
    end

    test "narrate/1 returns a log from a finished round" do
      time = 5
      round = %Round.Finished{time: time}
      assert Round.narrate(round) == []
    end

    test "simulate_tick/1 returns a round that is in progress with elapsed time" do
      time = 5
      round = %Round.InProgress{time: time}
      %Round.InProgress{elapsed_time: 1, time: ^time} = Round.simulate_tick(round)
    end

    test "simulate_tick/1 returns a finished round with elapsed time" do
      time = 1
      round = %Round.InProgress{time: time}
      %Round.Finished{elapsed_time: 1, time: ^time} = Round.simulate_tick(round)
    end
  end
end
