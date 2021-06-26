defmodule DjRumble.Chats.MessageTest do
  @moduledoc """
  Round tests
  """
  use DjRumble.DataCase
  use DjRumble.Support.Chats.MessageCase
  use ExUnit.Case

  import DjRumble.AccountsFixtures
  import DjRumble.RoomsFixtures

  describe "round" do
    alias DjRumble.Chats.Message

    @default_timezone "America/Buenos_Aires"

    test "create_message/4 :: (:user_message, message, %User{}, timezone) returns a %Message.User{}" do
      message = "Hello!"
      user = user_fixture()

      %Message.User{from: ^user, message: ^message} =
        create_message([:user_message, message, user, @default_timezone])
    end

    test "create_message/4 :: (:video_message, %Video{}, %User{}, action) returns a %Message.Video{}" do
      video = video_fixture()
      user = user_fixture()
      action = :playing

      %Message.Video{action: ^action, added_by: ^user, video: ^video} =
        create_message([:video_message, video, user, action])
    end

    test "narrate/1 :: (%Message.Video{action: :playing}) returns a message" do
      %{title: title} = video = video_fixture()
      %{username: username} = user = user_fixture()
      action = :playing

      message =
        create_message([:video_message, video, user, action])
        |> Message.narrate()

      4 = length(message)
      ["Now playing", ^title, "added by", ^username] = message
    end
  end
end
