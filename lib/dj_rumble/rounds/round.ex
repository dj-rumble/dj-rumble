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

  def finish(%Round.InProgress{} = round) do
    Round.Finished.new(
      round.id,
      round.time,
      round.elapsed_time,
      round.score,
      round.outcome,
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
    |> check_outcome()
    |> check_if_finished()
  end

  @doc """
  Given a `%Round.InProgress{elapsed_time: elapsed_time, time: time}` and a number of
  stages, returns a number representing the stage of the round, according to
  elapsed_time, where `elapsed_time` is the time has passed since the round
  started and `time` the total time of the round.

  ## Examples

      iex> %DjRumble.Rounds.Round.InProgress{time: 30, elapsed_time: 9}
      ...> |> Round.get_estimated_round_stage(3)
      1

      iex> %DjRumble.Rounds.Round.InProgress{time: 30, elapsed_time: 10}
      ...> |> Round.get_estimated_round_stage(3)
      2

      iex> %DjRumble.Rounds.Round.InProgress{time: 30, elapsed_time: 20}
      ...> |> Round.get_estimated_round_stage(3)
      3

      iex> %DjRumble.Rounds.Round.InProgress{time: 30, elapsed_time: 30}
      ...> |> Round.get_estimated_round_stage(3)
      3

  """
  @spec get_estimated_round_stage(%Round.InProgress{}, non_neg_integer) :: non_neg_integer
  def get_estimated_round_stage(%Round.InProgress{time: time}, _stages) when time <= 19, do: 1

  def get_estimated_round_stage(%Round.InProgress{time: time} = round, stages) when stages > 2 do
    %Round.InProgress{elapsed_time: elapsed_time} = round
    count = div(time, stages)
    chunks = Enum.chunk_every(Enum.to_list(0..time), count, count, :discard)
    Enum.count(chunks, &(elapsed_time >= Enum.max(&1) or elapsed_time in &1))
  end

  def get_estimated_round_stage(_round, _stages), do: 1

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

  defp check_outcome(%Round.InProgress{outcome: outcome, score: score} = round) do
    case get_outcome_by_score(score) do
      ^outcome ->
        round

      outcome ->
        %Round.InProgress{round | outcome: outcome}
    end
  end

  defp check_if_finished(
         %Round.InProgress{elapsed_time: elapsed_time, time: time, score: {dislikes, likes}} =
           round
       ) do
    case {time, dislikes, likes} do
      {n, _, _} when n == elapsed_time ->
        finish(round)

      {_, _positives, _negatives} ->
        %Round.InProgress{
          id: round.id,
          time: round.time,
          elapsed_time: round.elapsed_time,
          score: round.score,
          outcome: round.outcome,
          log: round.log
        }
    end
  end

  defp get_outcome_by_score({positives, negatives}) when positives < negatives do
    :thrown
  end

  defp get_outcome_by_score({positives, negatives}) when positives > negatives do
    :continue
  end

  defp get_outcome_by_score({_positives, _negatives}) do
    :thrown
  end

  defp log_action(%Round.InProgress{log: log} = round, action) do
    %Round.InProgress{round | log: Log.append(log, action)}
  end
end
