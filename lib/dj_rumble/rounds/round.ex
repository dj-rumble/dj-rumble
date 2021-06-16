defmodule DjRumble.Rounds.Round do
  @moduledoc """
  Responsible for defining a Round domain
  """
  import Algae

  alias DjRumble.Rounds.{
    Action,
    ActionsDeck,
    Log,
    Round
  }

  @type id :: String.t()

  defsum do
    defdata Scheduled do
      id :: Round.id() \\ ""
      time :: non_neg_integer() \\ 0
      elapsed_time :: non_neg_integer() \\ 0
      score :: {non_neg_integer(), non_neg_integer()} \\ {0, 0}
    end

    defdata InProgress do
      id :: Round.id() \\ ""
      time :: non_neg_integer() \\ 0
      elapsed_time :: non_neg_integer() \\ 0
      score :: {non_neg_integer(), non_neg_integer()} \\ {0, 0}
      outcome :: :continue | :thrown \\ :continue
      log :: Log.t()
    end

    defdata Finished do
      id :: Round.id() \\ ""
      time :: non_neg_integer() \\ 0
      elapsed_time :: non_neg_integer() \\ 0
      score :: {non_neg_integer(), non_neg_integer()} \\ {0, 0}
      outcome :: :continue | :thrown \\ :continue
      log :: Log.t()
    end
  end

  def schedule(time) do
    Round.Scheduled.new(Ecto.UUID.generate(), time)
  end

  def set_time(%Round.Scheduled{} = round, time) do
    %Round.Scheduled{round | time: time}
  end

  def set_score(%Round.InProgress{} = round, type) do
    {score, action} = apply_score(round, type)

    %Round.InProgress{round | score: score}
    |> log_action(action)
  end

  def start(%Round.Scheduled{} = round) do
    Round.InProgress.new(round.id, round.time, round.elapsed_time, round.score)
  end

  def finish(%Round.InProgress{} = round, outcome) do
    Round.Finished.new(
      round.id,
      round.time,
      round.elapsed_time,
      round.score,
      outcome,
      round.log
    )
  end

  def narrate(%Round.InProgress{} = round) do
    Log.narrate(round.log)
  end

  def narrate(%Round.Finished{} = round) do
    Log.narrate(round.log)
  end

  def simulate_tick(%Round.InProgress{} = round) do
    {time, _action} = track_time(round)

    round = %Round.InProgress{round | elapsed_time: time}

    round
    |> check_if_finished()
  end

  defp track_time(%Round.InProgress{} = round) do
    action = Action.from_properties(ActionsDeck.count_action_properties())
    time = Action.apply(action, round)
    {time, action}
  end

  defp apply_score(%Round.InProgress{} = round, type) do
    action = Action.from_properties(ActionsDeck.score_action_properties(type, round.elapsed_time))
    score = Action.apply(action, round)
    {score, action}
  end

  defp check_if_finished(
         %Round.InProgress{elapsed_time: elapsed_time, time: time, score: {dislikes, likes}} =
           round
       ) do
    case {time, dislikes, likes} do
      {n, positives, negatives} when n == elapsed_time ->
        finish(round, get_outcome(positives, negatives))

      {_, positives, negatives} ->
        %Round.InProgress{
          id: round.id,
          time: round.time,
          elapsed_time: round.elapsed_time,
          score: round.score,
          outcome: get_outcome(positives, negatives),
          log: round.log
        }
    end
  end

  defp get_outcome(positives, negatives) when positives < negatives do
    :thrown
  end

  defp get_outcome(positives, negatives) when positives > negatives do
    :continue
  end

  defp get_outcome(_positives, _negatives) do
    :continue
  end

  defp log_action(%Round.InProgress{log: log} = round, action) do
    %Round.InProgress{round | log: Log.append(log, action)}
  end
end
