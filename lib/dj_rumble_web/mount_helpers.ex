defmodule DjRumbleWeb.MountHelpers do
  @moduledoc """
  Responsible for implementing reusable mount helpers
  """
  import Phoenix.LiveView

  alias DjRumble.Accounts
  alias DjRumble.Accounts.User
  alias DjRumble.Chats.ChatSupervisor
  alias DjRumbleWeb.Channels

  @default_locale "en"
  @default_timezone "UTC"
  @default_timezone_offset 0

  @doc """
  Mount helper to assign defaults values to the socket. Includes: `%User{}` and
  browser locale, timezone and timezone offset.
  """
  def assign_defaults(socket, _params, session) do
    case connected?(socket) do
      true ->
        socket
        |> assign_user(session)
        |> assign_locale()
        |> assign_timezone()
        |> assign_timezone_offset()

      false ->
        socket
    end
  end

  @doc """
  Given a `socket` and a `room`, assigns a reference to a `chat_server` pid and
  it's `state` to the `socket`
  """
  @spec assign_chat(Phoenix.LiveView.Socket.t(), %DjRumble.Rooms.Room{}) ::
          Phoenix.LiveView.Socket.t()
  def assign_chat(socket, room) do
    chat_topic = Channels.get_topic(:room_chat, room.slug)
    :ok = Channels.subscribe(chat_topic)

    {chat_service, chat_service_state} = ChatSupervisor.get_server(ChatSupervisor, chat_topic)

    socket
    |> assign(:chat_messages, chat_service_state.messages)
    |> assign(:chat_service, chat_service)
    |> assign(:chat_service_state, chat_service_state)
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

  defp assign_locale(socket) do
    locale = get_connect_params(socket)["locale"] || @default_locale
    assign(socket, locale: locale)
  end

  defp assign_timezone(socket) do
    timezone = get_connect_params(socket)["timezone"] || @default_timezone
    assign(socket, timezone: timezone)
  end

  defp assign_timezone_offset(socket) do
    timezone_offset = get_connect_params(socket)["timezone_offset"] || @default_timezone_offset
    assign(socket, timezone_offset: timezone_offset)
  end
end
