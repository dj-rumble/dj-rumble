defmodule DjRumbleWeb.Live.Components.ConfettiFab do
  @moduledoc """
  Responsible for showing the confetti
  """

  use DjRumbleWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
