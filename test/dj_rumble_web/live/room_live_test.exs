defmodule DjRumbleWeb.RoomLiveTest do
  @moduledoc false

  use DjRumble.Support.Rooms.RoomCase
  use DjRumbleWeb.ConnCase

  import DjRumble.AccountsFixtures
  import DjRumble.RoomsFixtures
  import Phoenix.LiveViewTest

  alias DjRumble.Rooms.RoomSupervisor

  # @create_attrs %{name: "some name", slug: "some slug"}
  # @update_attrs %{name: "some updated name", slug: "some updated slug"}
  # @invalid_attrs %{name: nil, slug: nil}

  defp start_room_server(room) do
    {:ok, pid} = RoomSupervisor.start_room_server(RoomSupervisor, room)

    # Teardown
    on_exit(fn ->
      RoomSupervisor.terminate_room_server(RoomSupervisor, pid)
    end)

    :ok
  end

  describe "Index" do
    setup do
      servers_amount = 1
      room_servers = start_room_servers(servers_amount)

      %{rooms: rooms} = fetch_matchmaking_rooms()

      # Teardown
      on_exit(fn ->
        Enum.each(room_servers, fn %{pid: pid} ->
          RoomSupervisor.terminate_room_server(RoomSupervisor, pid)
        end)
      end)

      %{rooms: rooms}
    end

    test "lists all rooms", %{conn: conn, rooms: rooms} do
      {:ok, _index_live, html} = live(conn, Routes.room_index_path(conn, :index))

      assert html =~ "DJ Rooms"

      for {_current_round, room, _videos} <- rooms do
        assert html =~ room.name
      end
    end

    test "renders room player", %{conn: conn, rooms: rooms} do
      user = user_fixture()
      {_, %{slug: slug} = room, _} = hd(rooms)

      [video | _vs] = videos = videos_fixture(3)

      args = %{
        current_round: %{video: video, added_by: user},
        room: room,
        status: :playing,
        videos: videos
      }

      {:ok, index_live, _html} = live(conn, Routes.room_index_path(conn, :index))

      %{pid: view_pid} = index_live

      :erlang.trace(view_pid, true, [:receive])

      send(index_live.pid, {:receive_current_player, args})

      room_card_id = "dj-rumble-room-card-#{slug}"

      assert_receive(
        {
          :trace,
          ^view_pid,
          :receive,
          {
            :phoenix,
            :send_update,
            {
              DjRumbleWeb.Live.Components.RoomCard,
              ^room_card_id,
              %{
                current_round: %{added_by: ^user, video: ^video},
                status: :playing,
                videos: ^videos
              }
            }
          }
        },
        3000
      )
    end

    test "renders users count", %{conn: conn, rooms: rooms} do
      _show_conns =
        for {_current_round, %{slug: slug} = _room, _videos} <- rooms do
          conn =
            build_conn()
            |> get("/rooms/#{slug}")

          topic = DjRumbleWeb.Channels.get_topic(:room, slug)
          user = user_fixture()

          {:ok, _} =
            DjRumbleWeb.Presence.track(
              self(),
              topic,
              user.id,
              %{username: user.username, user_id: user.id}
            )

          conn
        end

      {:ok, index_live, _html} = live(conn, Routes.room_index_path(conn, :index))

      %{pid: view_pid} = index_live

      :erlang.trace(view_pid, true, [:receive])

      assert_receive({:trace, ^view_pid, :receive, :fetch_users_count}, 2000)
    end

    # test "saves new room", %{conn: conn} do
    #   {:ok, index_live, _html} = live(conn, Routes.room_index_path(conn, :index))

    #   assert index_live |> element("a", "New Room") |> render_click() =~
    #            "New Room"

    #   assert_patch(index_live, Routes.room_index_path(conn, :new))

    #   assert index_live
    #          |> form("#room-form", room: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   {:ok, _, html} =
    #     index_live
    #     |> form("#room-form", room: @create_attrs)
    #     |> render_submit()
    #     |> follow_redirect(conn, Routes.room_index_path(conn, :index))

    #   assert html =~ "Room created successfully"
    #   assert html =~ "some name"
    # end
  end

  describe "Show" do
    @search_video_open_modal_button_id "#djrumble-searchbox-modal-button-1"
    @search_video_close_modal_button_class ".modal-close-icon"
    @search_form_id "#search-form"
    @video_search_received_event_name "receive_search_completed_signal"

    @new_message_form_id "#new-message"

    @player_hook_id "#player-syncing-data"

    @positive_score_button "#djrumble-score-positive-button"
    @negative_score_button "#djrumble-score-negative-button"

    defp authenticated_conn(conn) do
      user = user_fixture()
      conn = log_in_user(conn, user)

      %{user: user, conn: conn}
    end

    defp search_video(view, search_query) do
      # Simulates a search video interaction
      # Opens modal
      view
      |> element(@search_video_open_modal_button_id)
      |> render_click()

      view
      |> element(@search_form_id)
      |> render_change(%{search_field: %{query: search_query}})

      view
      |> element(@search_form_id)
      |> render_submit(%{})

      assert_push_event(view, @video_search_received_event_name, %{})

      :ok
    end

    defp add_video(view) do
      view
      |> element("#search-element-button-1")
      |> render_click()

      # Closes the modal window
      view
      |> element(@search_video_close_modal_button_class)
      |> render_click()

      :ok
    end

    defp type_chat_message(view, message) do
      view
      |> element(@new_message_form_id)
      |> render_submit(%{submit: %{message: message}})

      :ok
    end

    defp vote_video(view, :positive) do
      view
      |> element(@positive_score_button)
      |> render_click()

      :ok
    end

    defp vote_video(view, :negative) do
      view
      |> element(@negative_score_button)
      |> render_click()

      :ok
    end

    setup(%{conn: conn}) do
      room = room_fixture(%{}, %{preload: true})
      :ok = start_room_server(room)

      %{conn: conn, room: room}
    end

    test "displays room with no videos", %{conn: conn, room: room} do
      {:ok, show_live, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))
      assert page_title(show_live) == nil
    end

    test "displays room navbar with a username", %{conn: conn, room: room} do
      %{user: user, conn: conn} = authenticated_conn(conn)

      {:ok, _show_live, html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      assert html =~
               "<span>\n      Hello, <span class=\"text-green-300 text-3xl\">#{user.username}</span>"
    end

    test "create a round", %{conn: conn, room: room} do
      %{user: _user, conn: conn} = authenticated_conn(conn)

      conn = get(conn, "/rooms/#{room.slug}")
      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      # Simulates a search video interaction
      search_query = "some video search"
      :ok = search_video(view, search_query)

      # Adds a video to the queue
      :ok = add_video(view)
    end

    test "receives a chat message", %{conn: conn, room: room} do
      %{user: user, conn: conn} = authenticated_conn(conn)

      # Establishes a connection
      conn = get(conn, "/rooms/#{room.slug}")
      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      message = "Hello there!"
      :ok = type_chat_message(view, message)

      :ok = Process.sleep(300)

      assert render(view) =~
               "<span class=\"text-xl font-bold text-gray-300\">#{user.username}:</span>"

      assert render(view) =~ "<span class=\"italic text-xl text-gray-300 \">#{message}</span>"
    end

    defp do_start_a_round(view, video_duration) do
      # Adds a video to the queue
      :ok = search_video(view, "some video")
      :ok = add_video(view)

      view
      |> element(@player_hook_id)
      |> render_hook(:player_is_ready, %{})

      view
      |> element(@player_hook_id)
      |> render_hook(:receive_video_time, %{duration: video_duration})

      :ok
    end

    test "a player connects, adds a video and a round is started", %{conn: conn, room: room} do
      %{user: user, conn: conn} = authenticated_conn(conn)

      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      %{pid: view_pid} = view

      :erlang.trace(view_pid, true, [:receive])

      video_duration = 30

      :ok = do_start_a_round(view, video_duration)

      assert_receive(
        {:trace, ^view_pid, :receive, {:request_playback_details, %{time: 0, videoId: _video_id}}}
      )

      assert_receive({
        :trace,
        ^view_pid,
        :receive,
        %Phoenix.Socket.Message{
          event: "event",
          payload: %{
            "cid" => nil,
            "event" => "receive_video_time",
            "type" => "hook",
            "value" => %{"duration" => ^video_duration}
          }
        }
      })

      assert_receive({:trace, ^view_pid, :receive, {:receive_countdown, 3000}}, 1000)
      assert_receive({:trace, ^view_pid, :receive, {:receive_countdown, 2000}}, 2000)
      assert_receive({:trace, ^view_pid, :receive, {:receive_countdown, 1000}}, 3000)
      assert_receive({:trace, ^view_pid, :receive, {:receive_countdown, 0}}, 3000)

      assert_receive(
        {
          :trace,
          ^view_pid,
          :receive,
          {:round_started,
           %{
             added_by: ^user,
             round: %DjRumble.Rounds.Round.InProgress{
               elapsed_time: 0,
               log: %DjRumble.Rounds.Log{actions: [], narrations: []},
               outcome: :continue,
               score: {0, 0},
               time: ^video_duration
             },
             video: %DjRumble.Rooms.Video{},
             video_details: %{time: 0, videoId: _video_id}
           }}
        },
        3000
      )
    end

    test "a player receive some playback details for a video", %{conn: conn, room: room} do
      conn = get(conn, "/rooms/#{room.slug}")
      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      %{pid: view_pid} = view

      :erlang.trace(view_pid, true, [:receive])

      video = video_fixture()
      round = %DjRumble.Rounds.Round.InProgress{time: 20}
      video_details = %{time: 5, videoId: video.video_id}
      user = user_fixture()

      args = %{
        round: round,
        video: video,
        video_details: video_details,
        added_by: user
      }

      send(view_pid, {:receive_playback_details, args})

      :ok = Process.sleep(300)

      assert page_title(view) =~ video.title
    end

    test "a message is received when there are no more rounds", %{conn: conn, room: room} do
      conn = get(conn, "/rooms/#{room.slug}")
      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      %{pid: view_pid} = view

      :erlang.trace(view_pid, true, [:receive])

      send(view_pid, :no_more_rounds)

      assert_receive({:trace, ^view_pid, :receive, :no_more_rounds})
    end

    test "a message is received when a round is finished with a :continue outcome", %{
      conn: conn,
      room: room
    } do
      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      %{pid: view_pid} = view

      :erlang.trace(view_pid, true, [:receive])

      round = %DjRumble.Rounds.Round.Finished{outcome: :continue, score: {1, 0}}
      video = video_fixture()
      video_details = %{title: video.title}

      send(
        view_pid,
        {:round_finished, %{round: round, video: video, video_details: video_details}}
      )

      short_title = String.slice(video_details.title, 0, 15)

      assert render(view) =~ "#{short_title}... scored 1 points"
    end

    test "a message is received when a round is finished with a :thrown outcome", %{
      conn: conn,
      room: room
    } do
      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      %{pid: view_pid} = view

      :erlang.trace(view_pid, true, [:receive])

      round = %DjRumble.Rounds.Round.Finished{outcome: :thrown, score: {0, 3}}
      video = video_fixture()
      video_details = %{title: video.title}

      send(
        view_pid,
        {:round_finished, %{round: round, video: video, video_details: video_details}}
      )

      short_title = String.slice(video_details.title, 0, 15)

      :ok = Process.sleep(900)

      assert render(view) =~ "#{short_title}... scored -3 points"
    end

    test "a chat message is received", %{conn: conn, room: room} do
      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      %{pid: view_pid} = view

      :erlang.trace(view_pid, true, [:receive])

      user = user_fixture()
      message_string = "some message"
      timestamp = "13:51:48"

      message = %DjRumble.Chats.Message.User{
        from: user,
        message: message_string,
        timestamp: timestamp
      }

      send(view_pid, {:receive_new_message, message})

      assert_receive({
        :trace,
        ^view_pid,
        :receive,
        {:receive_new_message, ^message}
      })

      assert_push_event(view, "receive_new_message", %{})
    end

    test "a score message is received when a positive vote is triggered", %{
      conn: conn,
      room: room
    } do
      %{conn: conn} = authenticated_conn(conn)

      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      %{pid: view_pid} = view

      :erlang.trace(view_pid, true, [:receive])

      video_duration = 30
      :ok = do_start_a_round(view, video_duration)

      :ok = Process.sleep(4500)

      :ok = vote_video(view, :positive)

      assert render(view) =~ "<span class=\"text-gray-400 text-5xl font-street-ruler\">1</span>"
    end

    test "a score message is received when a negative vote is triggered", %{
      conn: conn,
      room: room
    } do
      %{conn: conn} = authenticated_conn(conn)

      {:ok, view, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

      %{pid: view_pid} = view

      :erlang.trace(view_pid, true, [:receive])

      video_duration = 30
      :ok = do_start_a_round(view, video_duration)

      :ok = Process.sleep(4500)

      :ok = vote_video(view, :negative)

      assert render(view) =~ "<span class=\"text-gray-400 text-5xl font-street-ruler\">-1</span>"
    end
  end
end
