defmodule DjRumble.Rounds.ActionsDeck do
  @moduledoc """
  Responsible for defining Round actions
  """

  def count_action_properties do
    %{
      kind: :count_time,
      time: 1
    }
  end

  def score_action_properties(type, at_time) do
    %{
      kind: :score,
      amount: 1,
      type: type,
      at_time: at_time
    }
  end
end
