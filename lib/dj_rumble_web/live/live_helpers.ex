defmodule DjRumbleWeb.LiveHelpers do
  @moduledoc """
  Responsible for implementing reusable helpers for live views
  """
  import Phoenix.LiveView.Helpers

  @doc """
  Renders a component inside the `DjRumbleWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, DjRumbleWeb.RoomLive.FormComponent,
        id: @room.id || :new,
        action: @live_action,
        room: @room,
        return_to: Routes.room_index_path(@socket, :index) %>
  """
  def live_modal(socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(socket, DjRumbleWeb.ModalComponent, modal_opts)
  end
end
