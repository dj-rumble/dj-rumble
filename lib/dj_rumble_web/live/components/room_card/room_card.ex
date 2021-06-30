defmodule DjRumbleWeb.Live.Components.RoomCard do
  @moduledoc """
  Responsible for showing a room card
  """

  use DjRumbleWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:current_round, %{video: nil, added_by: nil})
     |> assign(:room, nil)
     |> assign(:status, :idle)
     |> assign(:videos, [])}
  end

  @impl true
  def update(assigns, socket) do
    %{current_round: current_round, room: room, status: status, videos: videos} = assigns

    {:ok,
     socket
     |> assign(:current_round, current_round)
     |> assign(:room, room)
     |> assign(:status, status)
     |> assign(:videos, videos)
     |> assign(assigns)}
  end

  defp is_playing(status) do
    status == :playing
  end

  defp get_player_info(current_round, status) do
    case status do
      :idle ->
        texts = ["So quiet in here...", "Come in and make some noise"]
        text = Enum.at(texts, Enum.random(0..(length(texts) - 1)))

        ~E"""
        <span><%= text %></span>
        """

      :playing ->
        %{video: video} = current_round

        ~E"""
        <span>Now playing <span><%= video.title %></span></span>
        """

      _ ->
        ~E"""
        <span>Taking a short break...</span>
        """
    end
  end
end
