defmodule DjRumbleWeb.MountHelpers do
  import Phoenix.LiveView

  alias DjRumble.Accounts
  alias DjRumble.Accounts.User

  def assign_defaults(socket, _params, session) do
    socket
    |> assign_user(session)
  end

  defp assign_user(socket, session) do
    user = Accounts.get_user_by_session_token(session["user_token"])

    %{user: user, visitor: visitor} =
      case user do
        nil ->
          %{user: %User{username: User.create_random_name()}, visitor: true}

        user ->
          %{user: user, visitor: false}
      end

    socket
    |> assign_new(:user, fn -> user end)
    |> assign_new(:visitor, fn -> visitor end)
  end
end
