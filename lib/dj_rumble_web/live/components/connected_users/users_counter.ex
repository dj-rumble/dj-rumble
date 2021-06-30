defmodule DjRumbleWeb.Live.Components.UsersCounter do
  @moduledoc """
  Responsible for showing the users counter for a room
  """
  use DjRumbleWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  defp get_icon_color(count) do
    case count do
      0 ->
        "text-gray-400"

      _ ->
        "text-green-600"
    end
  end

  defp render_svg do
    PhoenixInlineSvg.Helpers.svg_image(DjRumbleWeb.Endpoint, "icons/account", class: "w-8 h-8 m-0")
  end
end
