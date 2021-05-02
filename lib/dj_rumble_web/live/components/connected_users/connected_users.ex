defmodule DjRumbleWeb.Live.Components.ConnectedUsers do
  @moduledoc """
  Responsible for showing the active users in the room
  """

  use DjRumbleWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
