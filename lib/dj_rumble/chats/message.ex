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
      action :: :playing | :scheduled \\ :playing
      role :: :dj | :spectator | :system \\ :system
      args :: any() \\ nil
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
  def create_message(:user_message, message, user, timezone) do
    Message.User.new(user, message, timestamp(timezone))
  end

  def create_message(:video_message, video, user, {action, role, args}) do
    Message.Video.new(video, user, action, role, args)
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
      {:video, "#{video.title}"},
      "added by",
      {:username, "#{user.username}"}
    ]
  end

  def narrate(%Message.Video{
        video: video,
        added_by: user,
        action: :scheduled,
        role: :spectator,
        args: 0
      }) do
    [
      {:username, "#{user.username}"},
      "adds",
      {:video, "#{video.title}"},
      "and it's next to come"
    ]
  end

  def narrate(%Message.Video{
        video: video,
        added_by: user,
        action: :scheduled,
        role: :spectator,
        args: args
      }) do
    [
      {:username, "#{user.username}"},
      "adds",
      {:video, "#{video.title}"},
      "and it's placed",
      {:args, "##{args}"},
      "in the queue"
    ]
  end

  def narrate(%Message.Video{video: video, added_by: user, action: :scheduled, role: :dj, args: 0}) do
    [
      "💿 Dj",
      {:username, "#{user.username}"},
      "casts",
      {:video, "#{video.title}"},
      "to be next in queue"
    ]
  end

  def narrate(%Message.Video{
        video: video,
        added_by: user,
        action: :scheduled,
        role: :dj,
        args: args
      }) do
    [
      "💿 Dj",
      {:username, "#{user.username}"},
      "casts",
      {:video, "#{video.title}"},
      "to be",
      {:args, "##{args}"},
      "in queue"
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
