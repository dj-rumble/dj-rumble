defmodule DjRumbleWeb.Live.Components.ConnectedUsers do
  @moduledoc """
  Responsible for showing the active users in the room
  """

  use DjRumbleWeb, :live_component

  def update(assigns, socket) do
    connected_users =
      assigns.connected_users
      |> Enum.map(fn connected_user ->
        hd(connected_user.metas).username
      end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:connected_users, connected_users)}
  end
end
