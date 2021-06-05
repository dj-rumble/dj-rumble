defmodule DjRumbleWeb.Channels do
  @moduledoc """
  Responsible for declaring channel topics and subscriptions management.
  """

  @room_topic "room:<slug>"
  @player_is_ready_topic "room:<slug>:ready"
  @matchmaking_details_request_topic "matchmaking:<slug>:waiting_for_details"
  @initial_chat_request_topic "room:<slug>:request_initial_chat"

  def get_topic(:room), do: @room_topic

  def get_topic(:player_is_ready), do: @player_is_ready_topic

  def get_topic(:matchmaking_details_request), do: @matchmaking_details_request_topic

  def get_topic(:initial_chat_request), do: @initial_chat_request_topic

  def get_topic(type, slug), do: String.replace(get_topic(type), "<slug>", slug)

  def subscribe(type, slug) do
    Phoenix.PubSub.subscribe(DjRumble.PubSub, get_topic(type, slug))
  end

  def unsubscribe(type, slug) do
    Phoenix.PubSub.unsubscribe(DjRumble.PubSub, get_topic(type, slug))
  end

  def broadcast(type, slug, message) do
    Phoenix.PubSub.broadcast(DjRumble.PubSub, get_topic(type, slug), message)
  end

  def broadcast_from(pid, type, slug, message) do
    Phoenix.PubSub.broadcast_from(DjRumble.PubSub, pid, get_topic(type, slug), message)
  end
end
