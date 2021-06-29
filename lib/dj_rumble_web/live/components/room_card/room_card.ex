defmodule DjRumbleWeb.Live.Components.RoomCard do
  @moduledoc """
  Responsible for showing a room card
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Repo

  @impl true
  def update(assigns, socket) do
    %{matchmaking_server_state: matchmaking_server_state} = assigns

    IO.inspect(matchmaking_server_state)

    # videos = Enum.map(state.next_rounds, fn {_ref, {_pid, video, _ _user}} ->
    #   video
    # end)

    videos = Repo.preload(matchmaking_server_state.room, [:videos]).videos

    IO.inspect(videos)

    room = matchmaking_server_state.room

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:room, room)
     |> assign(:videos, videos)}
  end
end
