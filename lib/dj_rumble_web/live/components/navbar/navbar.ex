defmodule DjRumbleWeb.Live.Components.Navbar do
  @moduledoc """
  Responsible for displaying navbar controls
  """

  use DjRumbleWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  def render(assigns) do
    ~L"""
      <div class="flex flex-row-reverse text-gray-300">
        <%= render_navbar(assigns.visitor, assigns.username, assigns.homepage, @socket) %>
      </div>
    """
  end

  defp render_navbar(true, username, homepage, assigns) do
    ~L"""
      <%= render_item(%{to: Routes.user_registration_path(assigns, :new), method: nil, text: "Sign up"}, assigns) %>
      <%= render_item(%{to: Routes.user_session_path(assigns, :new), method: nil, text: "Sign in"}, assigns) %>
      <%= if homepage do %>
        <%= render_item(%{to: Routes.room_index_path(assigns, :index), method: nil, text: "Home"}, assigns) %>
      <% end %>
      <%= render_username(username, assigns) %>
    """
  end

  defp render_navbar(false, username, homepage, assigns) do
    ~L"""
      <%= render_item(%{to: Routes.user_session_path(assigns, :delete), method: :delete, text: "Log out"}, assigns) %>
      <%= render_item(%{to: Routes.user_settings_path(assigns, :index), method: nil, text: "Settings"}, assigns) %>
      <%= if homepage do %>
        <%= render_item(%{to: Routes.room_index_path(assigns, :index), method: nil, text: "Home"}, assigns) %>
      <% end %>
      <%= render_username(username, assigns) %>
    """
  end

  defp render_username(username, assigns) do
    ~L"""
      <div class="m-2">
        <p>
          Hello, <span class="text-green-300"><%= username %></span>
        </p>
      </div>
    """
  end

  defp render_item(%{to: to, method: method, text: text}, assigns) do
    ~L"""
      <div class="m-2">
        <%= link to: to, method: method,
          class: "text-gray-300 hover:text-green-300 transition duration-500 ease-in-out"
        do %>
          <%= text %>
        <% end %>
      </div>
    """
  end
end
