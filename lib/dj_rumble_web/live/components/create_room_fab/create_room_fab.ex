defmodule DjRumbleWeb.Live.Components.CreateRoomFab do
  @moduledoc """
  Responsible for displaying a create room button
  """

  use DjRumbleWeb, :live_component

  def update(assigns, conn) do
    {:ok,
     conn
     |> assign(assigns)}
  end
end
