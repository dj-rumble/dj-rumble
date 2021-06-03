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

  def set_score(%Round.InProgress{} = round, :positive) do
    {positives, negatives} = round.score
    %Round.InProgress{round | score: {positives + 1, negatives}}
  end

  def set_score(%Round.InProgress{} = round, :negative) do
    {positives, negatives} = round.score
    %Round.InProgress{round | score: {positives, negatives + 1}}
  end

  def start(%Round.Scheduled{} = round) do
    Round.InProgress.new(round.id, round.time, round.elapsed_time, round.score)
  end

  def finish(%Round.InProgress{} = round) do
    # TODO: do not just :continue but get the result calculated
    Round.Finished.new(
      round.id,
      round.time,
      round.elapsed_time,
      round.score,
      :continue,
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

  defp check_if_finished(
         %Round.InProgress{elapsed_time: elapsed_time, time: time, score: {dislikes, likes}} =
           round
       ) do
    case {time, dislikes, likes} do
      {n, _, _} when n == elapsed_time ->
        %Round.Finished{
          id: round.id,
          time: round.time,
          elapsed_time: round.elapsed_time,
          score: round.score,
          outcome: round.outcome,
          log: round.log
        }

      {_, n, _} when n >= 8 ->
        %Round.InProgress{
          id: round.id,
          time: round.time,
          elapsed_time: round.elapsed_time,
          score: round.score,
          outcome: :thrown,
          log: round.log
        }

      _ ->
        round
    end
  end

  # defp log_action(%Round.InProgress{log: log} = round, action) do
  #   %Round.InProgress{round | log: Log.append(log, action)}
  # end
end
