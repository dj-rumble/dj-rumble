defmodule DjRumbleWeb.ModalComponent do
  @moduledoc """
  Responsible for displaying a live modal component
  """
  use DjRumbleWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <div id="<%= @id %>" class="phx-modal"
      phx-capture-click="close_search_modal"
      phx-window-keydown="close_search_modal"
      phx-key="escape"
      phx-target="#<%= @id %>"
      phx-page-loading>

      <div class="phx-modal-content">
        <a class="phx-modal-close" phx-click="close_search_modal" href="">×</a>
        <%= live_component @socket, @component, @opts %>
      </div>
    </div>
    """
  end
end
