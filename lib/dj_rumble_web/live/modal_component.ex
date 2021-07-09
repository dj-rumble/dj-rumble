defmodule DjRumbleWeb.ModalComponent do
  @moduledoc """
  Responsible for displaying a live modal component
  """
  use DjRumbleWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <div id="<%= @id %>" class="phx-modal z-50"
      phx-capture-click="close_new_room_modal"
      phx-window-keydown="close_new_room_modal"
      phx-key="escape"
      phx-page-loading>

      <div class="phx-modal-content bg-gray-800 rounded-lg shadow-card">
        <a
          class="
            phx-modal-close
            transition duration-300 ease-in-out
            transform hover:scale-110 hover:text-gray-300
          "
          phx-click="close_new_room_modal"
        >
          ×
        </a>
        <%= live_component @socket, @component, @opts %>
      </div>
    </div>
    """
  end
end
