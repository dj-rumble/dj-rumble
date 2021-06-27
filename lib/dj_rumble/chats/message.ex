defmodule DjRumble.Chats.Message do
  @moduledoc """
  Defines a Message model that can be used by a chat to create messages. Views
  may check data structures using this model.
  """
  import Algae

  alias DjRumble.Accounts.User, as: AccountUser
  alias DjRumble.Chats.Message
  alias DjRumble.Rooms.Video

  @type id() :: String.t()
  @type user() :: AccountUser
  @type video() :: Video

  defsum do
    defdata User do
      from :: Message.user() \\ %AccountUser{}
      message :: String.t() \\ ""
      timestamp :: String.t() \\ ""
    end

    defdata Video do
      video :: Message.video() \\ %Video{}
      added_by :: Message.user() \\ %AccountUser{}
      action :: :playing | :added \\ :playing
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
  @spec create_message(
          :user_message | :video_message,
          DjRumble.Rooms.Video | binary,
          DjRumble.Accounts.User,
          :added | :playing | binary
        ) :: %{
          :__struct__ => DjRumble.Chats.Message.User | DjRumble.Chats.Message.Video,
          optional(:action) => :added | :playing,
          optional(:added_by) => DjRumble.Accounts.User,
          optional(:from) => DjRumble.Accounts.User,
          optional(:message) => binary,
          optional(:timestamp) => binary,
          optional(:video) => DjRumble.Rooms.Video
        }
  def create_message(:user_message, message, user, timezone) do
    Message.User.new(user, message, timestamp(timezone))
  end

  def create_message(:video_message, video, user, action) do
    Message.Video.new(video, user, action)
  end

  @doc """
  Given a `%Message{}`, returns a narrated event

  ## Examples

      iex> DjRumble.Chats.Message.narrate(
      ...>  %DjRumble.Chats.Message.Video{video: DjRumble.Rooms.Video{title: "my song"}},
      ...>  %DjRumble.Accounts.User{username: "some player"},
      ...>  action: :playing
      ...>)
      ["Now playing", "my song", "added_by", "some player"]

  """
  @spec narrate(DjRumble.Chats.Message.Video.t()) :: [String.t()]
  def narrate(%Message.Video{video: video, added_by: user, action: :playing}) do
    [
      "Now playing",
      "#{video.title}",
      "added by",
      "#{user.username}"
    ]
  end

  @doc """
  Given a timezone, returns a timestamp

  ## Examples

      iex> DjRumble.Chats.Message.timestamp("America/Buenos_Aires")
      "13:18:46"

  """
  @spec timestamp(binary) :: binary
  def timestamp(timezone) do
    DateTime.now(timezone, Tzdata.TimeZoneDatabase)
    |> elem(1)
    |> Time.to_string()
    |> String.split(".")
    |> hd
  end
end
