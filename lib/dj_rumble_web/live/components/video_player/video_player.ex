defmodule DjRumbleWeb.Live.Components.VideoPlayer do
  @moduledoc """
  Responsible for displaying the video player
  """

  use DjRumbleWeb, :live_component

  def update(assigns, conn) do
    {:ok,
      conn
      |> assign(assigns)
    }
  end
end
