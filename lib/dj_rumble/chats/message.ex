defmodule DjRumble.Chats.Message do
  @moduledoc """
  Responsible for defining a Message model
  """
  import Algae

  alias DjRumble.Accounts.User
  alias DjRumble.Chats.Message

  @type id() :: String.t()
  @type user() :: User

  defdata do
    user :: Message.user() \\ %User{}
    message :: String.t() \\ ""
  end

  @spec create_message(String.t(), DjRumble.Accounts.User) :: DjRumble.Chats.Message.t()
  def create_message(message, user) do
    Message.new(user, message)
  end
end
