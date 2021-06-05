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
end
