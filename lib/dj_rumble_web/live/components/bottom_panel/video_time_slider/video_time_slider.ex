defmodule DjRumbleWeb.Live.Components.PlayerControls.VideoTimeSlider do
  @moduledoc """
  Responsible for displaying the video time in a slider
  """

  use DjRumbleWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
