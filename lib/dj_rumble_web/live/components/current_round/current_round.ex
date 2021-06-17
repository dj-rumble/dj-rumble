defmodule DjRumbleWeb.Live.Components.CurrentRound do
  @moduledoc """
  Responsible for showing the current round
  """

  use DjRumbleWeb, :live_component

  def update(assigns, socket) do
    %{current_round: current_round} = assigns

    {:ok,
     socket
     |> assign(:current_round, current_round)}
  end

  defp render_dj(current_round, assigns) do
    case Map.get(current_round, :added_by) do
      nil ->
        ~L"""
        <span />
        """

      user ->
        ~L"""
        Added by <span class="text-green-400"><%= user.username%></span>
        """
    end
  end
end
