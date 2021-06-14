defmodule DjRumbleWeb.Live.Components.SearchFab do
  @moduledoc """
  Responsible for showing the searchbox
  """

  use DjRumbleWeb, :live_component

  @impl true
  def update(assigns, socket) do

    {click_event, event_target} = case assigns.is_search_enabled do
      true ->
        {"open", "djrumble-searchbox-modal-menu"}
      false ->
        {"open", "djrumble-register-modal-menu"}
    end

    {:ok,
     socket
     |> assign(:id, assigns.id)
     |> assign(:click_event, click_event)
     |> assign(:event_target, event_target)}
  end
end
