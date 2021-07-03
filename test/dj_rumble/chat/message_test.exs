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

    defp generate_round_in_progress(outcome, time, elapsed_time) do
      %Round.InProgress{outcome: outcome, time: time, elapsed_time: elapsed_time}
    end

    defp generate_score_messages(video, user, score_type, role, round, amount) do
      for _n <- 1..amount do
        create_message([:score_message, video, user, {score_type, role, round}])
      end
    end

    defp assert_score_message_is_in_narrations(%Message.Score{narration: narration} = message) do
      assert Message.get_round_narrations_by_stage(message)
             |> Map.values()
             |> Enum.reduce([], fn sub_narrations, acc ->
               acc ++ sub_narrations
             end)
             |> Enum.member?(narration)
    end

    defp assert_score_messages_are_in_narrations(messages) do
      for message <- messages do
        assert_score_message_is_in_narrations(message)
      end
    end

    defp test_score_messages_are_narrated(score_type, role, outcome, amount_per_round_stage) do
      # Setup
      %Video{} = video = video_fixture()
      %User{} = user = user_fixture()

      # Tests messages for rounds in stage 1
      round = generate_round_in_progress(outcome, 30, 5)

      messages =
        generate_score_messages(video, user, score_type, role, round, amount_per_round_stage)

      assert_score_messages_are_in_narrations(messages)

      # Tests messages for rounds in stage 2
      round = generate_round_in_progress(outcome, 30, 15)

      messages =
        generate_score_messages(video, user, score_type, role, round, amount_per_round_stage)

      assert_score_messages_are_in_narrations(messages)

      # Tests messages for rounds in stage 3
      round = generate_round_in_progress(outcome, 30, 25)

      messages =
        generate_score_messages(video, user, score_type, role, round, amount_per_round_stage)

      assert_score_messages_are_in_narrations(messages)
    end

    defp assert_video_message_is_in_narrations(%Message.Video{narration: narration} = message) do
      assert Message.get_finished_round_narrations(message)
             |> Enum.member?(narration)
    end

    defp assert_video_messages_are_in_narrations(messages) do
      for message <- messages do
        assert_video_message_is_in_narrations(message)
      end
    end

    defp test_video_messages_are_narrated(action, role, outcome, score, next_tracks_count) do
      # Setup
      %Video{} = video = video_fixture()
      %User{} = user = user_fixture()
      args = {score, outcome, next_tracks_count}

      # Exercise
      message =
        create_message([:video_message, video, user, {action, role, args}])
        |> Message.narrate()

      # Verify
      assert_video_messages_are_in_narrations([message])
    end

    test "create_message/4 :: (:user_message, message, %User{}, timezone) returns a %Message.User{}" do
      # Setup
      message = "Hello!"
      %User{} = user = user_fixture()

      # Exercise
      %Message.User{from: ^user, message: ^message} =
        create_message([:user_message, message, user, @default_timezone])
    end

    test "create_message/4 :: (:video_message, %Video{}, %User{}, action) returns a %Message.Video{}" do
      # Setup
      %Video{} = video = video_fixture()
      %User{} = user = user_fixture()
      action = :playing

      # Exercise & Verify
      %Message.Video{action: ^action, added_by: ^user, video: ^video} =
        create_message([:video_message, video, user, action])
    end

    test "create_message/4 :: (:video_message, %Video{}, %User{}, {:scheduled, :dj, args}) returns a %Message.Video{}" do
      # Setup
      %Video{} = video = video_fixture()
      %User{} = user = user_fixture()
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
      %Video{title: title} = video = video_fixture()
      %User{username: username} = user = user_fixture()
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

    test "narrate/1 :: (%Message.Video{action: :scheduled, role: :spectator, args: 0}) returns a narration" do
      # Setup
      %Video{title: title} = video = video_fixture()
      %User{username: username} = user = user_fixture()
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

    test "narrate/1 :: (%Message.Video{action: :finished, role: :spectator, args: {score, :continue, 0}}) returns a narration" do
      test_video_messages_are_narrated(:finished, :spectator, :continue, {1, 0}, 0)
    end

    test "narrate/1 :: (%Message.Video{action: :finished, role: :spectator, args: {score, :thrown, 0}}) returns a narration" do
      test_video_messages_are_narrated(:finished, :spectator, :thrown, {1, 0}, 0)
    end

    test "narrate/1 :: (%Message.Video{action: :finished, role: :spectator, args: {score, :continue, 2}}) returns a narration" do
      test_video_messages_are_narrated(:finished, :spectator, :continue, {1, 0}, 2)
    end

    test "narrate/1 :: (%Message.Video{action: :finished, role: :spectator, args: {score, :thrown, 2}}) returns a narration" do
      test_video_messages_are_narrated(:finished, :spectator, :thrown, {1, 0}, 2)
    end

    test "narrate/1 :: (%Message.Video{action: :finished, role: :dj, args: {score, :continue, 0}}) returns a narration" do
      test_video_messages_are_narrated(:finished, :dj, :continue, {1, 0}, 0)
    end

    test "narrate/1 :: (%Message.Video{action: :finished, role: :dj, args: {score, :thrown, 0}}) returns a narration" do
      test_video_messages_are_narrated(:finished, :dj, :thrown, {1, 0}, 0)
    end

    test "narrate/1 :: (%Message.Video{action: :finished, role: :dj, args: {score, :continue, 2}}) returns a narration" do
      test_video_messages_are_narrated(:finished, :dj, :continue, {1, 0}, 2)
    end

    test "narrate/1 :: (%Message.Video{action: :finished, role: :dj, args: {score, :thrown, 2}}) returns a narration" do
      test_video_messages_are_narrated(:finished, :dj, :thrown, {1, 0}, 2)
    end

    test "narrate/1 :: (%Message.Video{action: :finished, role: :spectator, args: 10}) returns a narration" do
      # Setup
      %Video{title: title} = video = video_fixture()
      %User{username: username} = user = user_fixture()
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

    test "narrate/1 :: (%Message.Video{action: :scheduled, role: :dj, args: 0}) returns a narration" do
      # Setup
      %Video{title: title} = video = video_fixture()
      %User{username: username} = user = user_fixture()
      remaining_rounds = 0
      action = :scheduled
      role = :dj
      args = remaining_rounds

      # Exercise
      message =
        create_message([:video_message, video, user, {action, role, args}])
        |> Message.narrate()

      # Verify
      6 = length(message)

      [
        {:emoji, "💿"},
        "Dj",
        {:username, ^username},
        "casts",
        {:video, ^title},
        "to be next in queue"
      ] = message
    end

    test "narrate/1 :: (%Message.Video{action: :scheduled, role: :dj, args: 10}) returns a narration" do
      # Setup
      %Video{title: title} = video = video_fixture()
      %User{username: username} = user = user_fixture()
      remaining_rounds = 10
      action = :scheduled
      role = :dj
      args = remaining_rounds

      # Exercise
      message =
        create_message([:video_message, video, user, {action, role, args}])
        |> Message.narrate()

      # Verify
      8 = length(message)
      expected_args = "##{args}"

      [
        {:emoji, "💿"},
        "Dj",
        {:username, ^username},
        "casts",
        {:video, ^title},
        "to be",
        {:args, ^expected_args},
        "in queue"
      ] = message
    end

    test "narrate/1 :: (%Message.Score{score_type: :positive, role: :dj, %Round.InProgress{outcome: :continue}}) returns a narration" do
      test_score_messages_are_narrated(:positive, :dj, :continue, 40)
    end

    test "narrate/1 :: (%Message.Score{score_type: :negative, role: :dj, %Round.InProgress{outcome: :continue}}) returns a narration" do
      test_score_messages_are_narrated(:negative, :dj, :continue, 40)
    end

    test "narrate/1 :: (%Message.Score{score_type: :positive, role: :dj, %Round.InProgress{outcome: :thrown}}) returns a narration" do
      test_score_messages_are_narrated(:positive, :dj, :thrown, 40)
    end

    test "narrate/1 :: (%Message.Score{score_type: :negative, role: :dj, %Round.InProgress{outcome: :thrown}}) returns a narration" do
      test_score_messages_are_narrated(:negative, :dj, :thrown, 40)
    end

    test "narrate/1 :: (%Message.Score{score_type: :positive, role: :spectator, %Round.InProgress{outcome: :continue}}) returns a narration" do
      test_score_messages_are_narrated(:positive, :spectator, :continue, 40)
    end

    test "narrate/1 :: (%Message.Score{score_type: :negative, role: :spectator, %Round.InProgress{outcome: :continue}}) returns a narration" do
      test_score_messages_are_narrated(:negative, :spectator, :continue, 40)
    end

    test "narrate/1 :: (%Message.Score{score_type: :positive, role: :spectator, %Round.InProgress{outcome: :thrown}}) returns a narration" do
      test_score_messages_are_narrated(:positive, :spectator, :thrown, 40)
    end

    test "narrate/1 :: (%Message.Score{score_type: :negative, role: :spectator, %Round.InProgress{outcome: :thrown}}) returns a narration" do
      test_score_messages_are_narrated(:negative, :spectator, :thrown, 40)
    end
  end
end
