defmodule DjRumbleWeb.Live.Components.CurrentRound do
  @moduledoc """
  Responsible for showing the current round
  """

  use DjRumbleWeb, :live_component

  def mount(socket) do
    {:ok,
     socket
     |> assign(:is_playing, false)}
  end

  def update(assigns, socket) do
    %{current_round: current_round} = assigns

    %{video: video} = current_round

    is_playing_video = video.video_id != "placeholder"

    {:ok,
     socket
     |> assign(:is_playing, is_playing_video)
     |> assign(:current_round, current_round)}
  end

  defp render_title(title, true, _assigns), do: title

  defp render_title(title, false, assigns) do
    ~L"""
    <span class="animate-pulse text-yellow-800"><%= title %></span>
    """
  end

  defp render_dj(_current_round, false, assigns) do
    ~L"""
    <span />
    """
  end

  defp render_dj(current_round, true, assigns) do
    case Map.get(current_round, :added_by) do
      nil ->
        render_dj(current_round, false, assigns)

      user ->
        ~L"""
        Added by <span class="text-gray-300 font-bold"><%= user.username%></span>
        """
    end
  end
end
