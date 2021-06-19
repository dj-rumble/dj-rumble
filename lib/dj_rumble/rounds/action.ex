defmodule DjRumble.Rounds.Action do
  @moduledoc """
  Responsible for defining Round actions
  """
  import Algae

  alias DjRumble.Rounds.Action

  defsum do
    defdata CountTime do
      time :: non_neg_integer() \\ 1
    end

    defdata Score do
      type :: :positive | :negative \\ :positive
      amount :: non_neg_integer() \\ 1
      at_time :: non_neg_integer() \\ 0
    end
  end

  def apply(%Action.CountTime{time: time} = _action, round) do
    round.elapsed_time + time
  end

  def apply(%Action.Score{type: :positive, amount: amount} = _action, round) do
    {positives, negatives} = round.score
    {positives + amount, negatives}
  end

  def apply(%Action.Score{type: :negative, amount: amount} = _action, round) do
    {positives, negatives} = round.score
    {positives, negatives + amount}
  end

  def from_properties(properties) when is_map(properties) do
    case properties.kind do
      :count_time ->
        %Action.CountTime{
          time: properties.time
        }

      :score ->
        %Action.Score{
          type: properties.type,
          amount: properties.amount,
          at_time: properties.at_time
        }
    end
  end
end
