defmodule DjRumbleWeb.Live.Components.RoundInfo do
  @moduledoc """
  Responsible for displaying Round info
  """

  use DjRumbleWeb, :live_component

  def update(assigns, conn) do
    {:ok,
     conn
     |> assign(assigns)}
  end
end
