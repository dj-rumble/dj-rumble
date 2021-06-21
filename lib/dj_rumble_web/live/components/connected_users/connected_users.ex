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

  defp render_users(me, users, assigns) do
    users =
      Enum.map(Enum.with_index(users), fn {user, index} ->
        has_separator = index != length(users) - 1

        case user do
          ^me -> render_user(user, "text-green-300", has_separator, assigns)
          _ -> render_user(user, "text-gray-300", has_separator, assigns)
        end
      end)

    ~L"""
      <%= for user <- users do %>
        <%= user %>
      <% end %>
    """
  end

  defp render_user(user, classes, has_separator, assigns) do
    ~L"""
      <span class="<%= classes %>">
        <%= user %><%= if has_separator do %>,<% end %>
      </span>
    """
  end
end
