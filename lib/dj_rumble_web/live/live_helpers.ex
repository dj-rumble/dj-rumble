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
  def live_modal(_socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(DjRumbleWeb.ModalComponent, modal_opts)
  end

  @spec render_tooltip(keyword) :: any
  @doc """
  Given some options renders a tooltip component.

  > The parent component must use the tailwind class `group` to bind events to
  > the child tooltip.

  ## Examples

      <%= render_tooltip(text: "Some awesome message") %>

      <%= render_tooltip(
        text: "Another awesome message"),
        extra_classes: "text-lg text-red-800"
      %>

  """
  def render_tooltip(opts) do
    opts = Keyword.merge([extra_classes: "", text: ""], opts)
    Phoenix.View.render(DjRumbleWeb.TooltipView, "tooltip.html", opts)
  end
end
