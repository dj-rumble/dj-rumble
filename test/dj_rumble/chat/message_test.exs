defmodule DjRumble.Chats.MessageTest do
  @moduledoc """
  Message model tests
  """
  use DjRumble.DataCase
  use DjRumble.Support.Chats.MessageCase
  use ExUnit.Case

  import DjRumble.AccountsFixtures
  import DjRumble.RoomsFixtures

  alias DjRumble.Accounts.User
  alias DjRumble.Rooms.Video
  alias DjRumble.Rounds.Round

  describe "round" do
    alias DjRumble.Chats.Message

    @default_timezone "America/Buenos_Aires"

    test "create_message/4 :: (:user_message, message, %User{}, timezone) returns a %Message.User{}" do
      # Setup
      message = "Hello!"
      user = user_fixture()

      # Exercise
      %Message.User{from: ^user, message: ^message} =
        create_message([:user_message, message, user, @default_timezone])
    end

    test "create_message/4 :: (:video_message, %Video{}, %User{}, action) returns a %Message.Video{}" do
      # Setup
      video = video_fixture()
      user = user_fixture()
      action = :playing

      # Exercise & Verify
      %Message.Video{action: ^action, added_by: ^user, video: ^video} =
        create_message([:video_message, video, user, action])
    end

    test "create_message/4 :: (:video_message, %Video{}, %User{}, {:scheduled, :dj, args}) returns a %Message.Video{}" do
      # Setup
      video = video_fixture()
      user = user_fixture()
      remaining_rounds = 420
      action = :scheduled
      role = :dj
      args = remaining_rounds

      # Exercise & Verify
      %Message.Video{action: ^action, added_by: ^user, args: ^args, role: ^role, video: ^video} =
        create_message([:video_message, video, user, {action, role, args}])
    end

    test "create_message/4 :: (:score_message, %Video{}, %User{}, {:positive, :spectator, %Round{}}) returns a %Message.Score{}" do
      # Setup
      %Video{} = video = video_fixture()
      %User{} = user = user_fixture()
      score_type = :positive
      role = :spectator

      %Round.InProgress{} =
        round = %Round.InProgress{elapsed_time: 10, time: 20, score: {10, 5}, outcome: :continue}

      # Exercise & Verify
      %Message.Score{
        role: ^role,
        round: ^round,
        score_type: ^score_type,
        scored_by: ^user,
        video: ^video
      } = create_message([:score_message, video, user, {score_type, role, round}])
    end

    test "narrate/1 :: (%Message.Video{action: :playing}) returns a message" do
      # Setup
      %{title: title} = video = video_fixture()
      %{username: username} = user = user_fixture()
      action = :playing

      # Exercise
      message =
        create_message([:video_message, video, user, action])
        |> Message.narrate()

      # Verify
      4 = length(message)

      [
        "Now playing",
        {:video, ^title},
        "added by",
        {:username, ^username}
      ] = message
    end

    test "narrate/1 :: (%Message.Video{action: :scheduled, role: :spectator, args: 0}) returns a message" do
      # Setup
      %{title: title} = video = video_fixture()
      %{username: username} = user = user_fixture()
      remaining_rounds = 0
      action = :scheduled
      role = :spectator
      args = remaining_rounds

      # Exercise
      message =
        create_message([:video_message, video, user, {action, role, args}])
        |> Message.narrate()

      # Verify
      4 = length(message)
      [{:username, ^username}, "adds", {:video, ^title}, "and it's next to come"] = message
    end

    test "narrate/1 :: (%Message.Video{action: :scheduled, role: :spectator, args: 10}) returns a message" do
      # Setup
      %{title: title} = video = video_fixture()
      %{username: username} = user = user_fixture()
      remaining_rounds = 10
      action = :scheduled
      role = :spectator
      args = remaining_rounds

      # Exercise
      message =
        create_message([:video_message, video, user, {action, role, args}])
        |> Message.narrate()

      # Verify
      6 = length(message)
      expected_args = "##{args}"

      [
        {:username, ^username},
        "adds",
        {:video, ^title},
        "and it's placed",
        {:args, ^expected_args},
        "in the queue"
      ] = message
    end

    test "narrate/1 :: (%Message.Video{action: :scheduled, role: :dj, args: 0}) returns a message" do
      # Setup
      %{title: title} = video = video_fixture()
      %{username: username} = user = user_fixture()
      remaining_rounds = 0
      action = :scheduled
      role = :dj
      args = remaining_rounds

      # Exercise
      message =
        create_message([:video_message, video, user, {action, role, args}])
        |> Message.narrate()

      # Verify
      5 = length(message)
      ["💿 Dj", {:username, ^username}, "casts", {:video, ^title}, "to be next in queue"] = message
    end

    test "narrate/1 :: (%Message.Video{action: :scheduled, role: :dj, args: 10}) returns a message" do
      # Setup
      %{title: title} = video = video_fixture()
      %{username: username} = user = user_fixture()
      remaining_rounds = 10
      action = :scheduled
      role = :dj
      args = remaining_rounds

      # Exercise
      message =
        create_message([:video_message, video, user, {action, role, args}])
        |> Message.narrate()

      # Verify
      7 = length(message)
      expected_args = "##{args}"

      [
        "💿 Dj",
        {:username, ^username},
        "casts",
        {:video, ^title},
        "to be",
        {:args, ^expected_args},
        "in queue"
      ] = message
    end
  end
end
