defmodule DjRumble.Collections do
  @moduledoc """
  The Collections context.
  """

  import Ecto.Query, warn: false
  alias DjRumble.Repo

  alias DjRumble.Collections.UserRoomVideo

  @doc """
  Returns the list of users_rooms_videos.

  ## Examples

      iex> list_users_rooms_videos()
      [%UserRoomVideo{}, ...]

  """
  def list_users_rooms_videos do
    Repo.all(UserRoomVideo)
  end

  @doc """
  Gets a single user_room_video.

  Raises `Ecto.NoResultsError` if the User room video does not exist.

  ## Examples

      iex> get_user_room_video!(123)
      %UserRoomVideo{}

      iex> get_user_room_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_room_video!(id), do: Repo.get!(UserRoomVideo, id)

  @doc """
  Creates a user_room_video.

  ## Examples

      iex> create_user_room_video(%{field: value})
      {:ok, %UserRoomVideo{}}

      iex> create_user_room_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_room_video(attrs \\ %{}) do
    %UserRoomVideo{}
    |> UserRoomVideo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_room_video.

  ## Examples

      iex> update_user_room_video(user_room_video, %{field: new_value})
      {:ok, %UserRoomVideo{}}

      iex> update_user_room_video(user_room_video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_room_video(%UserRoomVideo{} = user_room_video, attrs) do
    user_room_video
    |> UserRoomVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_room_video.

  ## Examples

      iex> delete_user_room_video(user_room_video)
      {:ok, %UserRoomVideo{}}

      iex> delete_user_room_video(user_room_video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_room_video(%UserRoomVideo{} = user_room_video) do
    Repo.delete(user_room_video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_room_video changes.

  ## Examples

      iex> change_user_room_video(user_room_video)
      %Ecto.Changeset{data: %UserRoomVideo{}}

  """
  def change_user_room_video(%UserRoomVideo{} = user_room_video, attrs \\ %{}) do
    UserRoomVideo.changeset(user_room_video, attrs)
  end
end
