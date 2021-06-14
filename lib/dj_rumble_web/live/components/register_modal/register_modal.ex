defmodule DjRumbleWeb.Live.Components.RegisterModal do
  @moduledoc """
  Responsible for displaying a modal that invites spectators to register.
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Accounts
  alias DjRumble.Accounts.User

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:changeset, Accounts.change_user_registration(%User{}))
     |> assign(:title, "Become a DJ and start voting!")
     |> assign(assigns)}
  end
end
