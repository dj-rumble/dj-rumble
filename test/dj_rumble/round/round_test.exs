defmodule DjRumble.Round.RoundTest do
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

    test "set_time/2 returns an updated scheduled round" do
      time = 10

      %Round.Scheduled{elapsed_time: elapsed_time, time: ^time, score: score} =
        Round.set_time(%Round.Scheduled{}, time)

      assert elapsed_time == 0
      assert score == {0, 0}
    end

    test "set_score/2 returns a round with a positive score" do
      # Setup
      time = 30
      elapsed_time = 2
      round = %Round.InProgress{time: time, elapsed_time: elapsed_time}

      # Exercise
      round = Round.set_score(round, :positive)

      # Verify
      %Round.InProgress{
        time: ^time,
        elapsed_time: ^elapsed_time,
        score: {1, 0}
      } = round
    end

    test "set_score/2 returns a round with a negative score" do
      # Setup
      time = 30
      elapsed_time = 2
      round = %Round.InProgress{time: time, elapsed_time: elapsed_time}

      # Exercise
      round = Round.set_score(round, :negative)

      # Verify
      %Round.InProgress{
        time: ^time,
        elapsed_time: ^elapsed_time,
        score: {0, 1}
      } = round
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

    test "finish/2 returns a finished round" do
      time = 5
      round = %Round.InProgress{time: time}
      outcome = :continue

      %Round.Finished{
        time: ^time,
        elapsed_time: elapsed_time,
        score: score,
        log: log,
        outcome: ^outcome
      } = Round.finish(round, outcome)

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

    test "simulate_tick/1 given a round that is in progress with a :thrown outcome returns a round that is in progress with a :continue outcome when positives score points are greater than negatives score points" do
      time = 5
      outcome = :thrown
      score = {2, 1}
      round = %Round.InProgress{time: time, score: score, outcome: outcome}
      %Round.InProgress{time: ^time, outcome: :continue} = Round.simulate_tick(round)
    end

    test "simulate_tick/1 given a round that is in progress with a :continue outcome returns a round that is in progress with a :thrown outcome when positives score points are smaller than negatives score points" do
      time = 5
      outcome = :continue
      score = {1, 2}
      round = %Round.InProgress{time: time, score: score, outcome: outcome}
      %Round.InProgress{time: ^time, outcome: :thrown} = Round.simulate_tick(round)
    end

    test "simulate_tick/1 given a round that is in progress with a :continue outcome returns a round that is in progress with the same :continue outcome when positives score points are greater than negatives score points" do
      time = 5
      outcome = :continue
      score = {2, 1}
      round = %Round.InProgress{time: time, score: score, outcome: outcome}
      %Round.InProgress{time: ^time, outcome: :continue} = Round.simulate_tick(round)
    end

    test "simulate_tick/1 given a round that is in progress with a :thrown outcome returns a round that is in progress with the same :thrown outcome when positives score points are smaller than negatives score points" do
      time = 5
      outcome = :thrown
      score = {1, 2}
      round = %Round.InProgress{time: time, score: score, outcome: outcome}
      %Round.InProgress{time: ^time, outcome: :thrown} = Round.simulate_tick(round)
    end

    test "simulate_tick/1 given a round that is in progress with a :thrown outcome returns a finished round with a :continue outcome when positives score points are greater than negatives score points" do
      time = 1
      outcome = :thrown
      score = {2, 1}
      round = %Round.InProgress{time: time, score: score, outcome: outcome}
      %Round.Finished{time: ^time, outcome: :continue} = Round.simulate_tick(round)
    end

    test "simulate_tick/1 given a round that is in progress with a :continue outcome returns a finished round with a :thrown outcome when positives score points are smaller than negatives score points" do
      time = 1
      outcome = :continue
      score = {1, 2}
      round = %Round.InProgress{time: time, score: score, outcome: outcome}
      %Round.Finished{time: ^time, outcome: :thrown} = Round.simulate_tick(round)
    end

    test "simulate_tick/1 given a round that is in progress with a :continue outcome returns a finished round with the same :continue outcome when positives score points are greater than negatives score points" do
      time = 1
      outcome = :continue
      score = {2, 1}
      round = %Round.InProgress{time: time, score: score, outcome: outcome}
      %Round.Finished{time: ^time, outcome: :continue} = Round.simulate_tick(round)
    end

    test "simulate_tick/1 given a round that is in progress with a :thrown outcome returns a finished round with the same :thrown outcome when positives score points are smaller than negatives score points" do
      time = 1
      outcome = :thrown
      score = {1, 2}
      round = %Round.InProgress{time: time, score: score, outcome: outcome}
      %Round.Finished{time: ^time, outcome: :thrown} = Round.simulate_tick(round)
    end
  end
end
