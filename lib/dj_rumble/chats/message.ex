defmodule DjRumble.Chats.Message do
  @moduledoc """
  Defines a Message model that can be used by a chat to create messages. Views
  may check data structures using this model.
  """
  import Algae

  alias DjRumble.Accounts.User
  alias DjRumble.Chats.Message

  @type id() :: String.t()
  @type user() :: User

  defsum do
    defdata User do
      from :: Message.user() \\ %User{}
      message :: String.t() \\ ""
      timestamp :: String.t() \\ ""
    end

    defdata Notice do
      from :: Message.user() \\ %User{}
      message :: String.t() \\ ""
      timestamp :: String.t() \\ ""
    end
  end

  @doc """
  Given a `type`, a `message`, a `user` and a `timezone`, returns a new `Message`.

  ## Examples

      iex> DjRumble.Chats.Message.create_message(
      ...>   :user_message,
      ...>   "Hello!",
      ...>   %DjRumble.Accounts.User{},
      ...>   "America/Buenos_Aires"
      ...> )
      %DjRumble.Chats.Message.User{
        message: "Hello!",
        timestamp: "13:51:48",
        user: #DjRumble.Accounts.User<...>
      }

  """
  @spec create_message(atom(), String.t(), DjRumble.Accounts.User, String.t()) ::
          DjRumble.Chats.Message.t()
  def create_message(:user_message, message, user, timezone) do
    Message.User.new(user, message, timestamp(timezone))
  end

  @doc """
  Given a timezone, returns a timestamp

  ## Examples

      iex> DjRumble.Chats.Message.timestamp("America/Buenos_Aires")
      "13:18:46"

  """
  def timestamp(timezone) do
    DateTime.now(timezone, Tzdata.TimeZoneDatabase)
    |> elem(1)
    |> Time.to_string()
    |> String.split(".")
    |> hd
  end
end
