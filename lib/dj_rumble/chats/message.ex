defmodule DjRumble.Chats.Message do
  @moduledoc """
  Defines a Message model that can be used by a chat to create messages. Views
  may check data structures using this model.
  """
  import Algae

  alias DjRumble.Accounts.User
  alias DjRumble.Chats.Message
  alias DjRumble.Rooms.Video

  @type id() :: String.t()
  @type user() :: User
  @type video() :: Video

  defsum do
    defdata User do
      from :: Message.user() \\ %User{}
      message :: String.t() \\ ""
      timestamp :: String.t() \\ ""
    end

    defdata Video do
      video :: Message.video() \\ %Video{}
      user :: Message.user() \\ %User{}
      action :: :playing | :added \\ :playing
    end
  end

  @spec create_message(
          :user_message | :video_message,
          DjRumble.Rooms.Video | binary,
          DjRumble.Accounts.User,
          :added | :playing | binary
        ) :: %{
          :__struct__ => DjRumble.Chats.Message.User | DjRumble.Chats.Message.Video,
          optional(:action) => :added | :playing,
          optional(:from) => DjRumble.Accounts.User,
          optional(:message) => binary,
          optional(:timestamp) => binary,
          optional(:user) => DjRumble.Accounts.User,
          optional(:video) => DjRumble.Rooms.Video
        }
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
  def create_message(:user_message, message, user, timezone) do
    Message.User.new(user, message, timestamp(timezone))
  end

  def create_message(:video_message, video, user, action) do
    Message.Video.new(video, user, action)
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
