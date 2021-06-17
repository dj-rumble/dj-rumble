defmodule DjRumble.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias DjRumble.Repo

  alias DjRumble.Rooms.{Room, Supervisor}

  defdelegate child_spec(init_arg), to: Supervisor

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  @doc """
  Gets a single room by slug.

  Raises `Ecto.NoResultsError` if the User room does not exist.

  ## Examples

      iex> get_room_by_slug(slug)
      %Room{}

      iex> get_room_by_slug(bad_value)
      ** nil

  """
  def get_room_by_slug(slug) do
    Repo.get_by(Room, %{slug: slug})
  end

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  @doc """
  Returns a preloaded `%Room{}`.

  ## Examples

      iex> Rooms.preload_room(room)
      %Room{}

  """
  def preload_room(%Room{} = room, attrs \\ []) do
    Repo.preload(room, attrs)
  end

  alias DjRumble.Rooms.Video

  @doc """
  Returns the list of videos.

  ## Examples

      iex> list_videos()
      [%Video{}, ...]

  """
  def list_videos do
    Repo.all(Video)
  end

  @doc """
  Gets a single video.

  Raises `Ecto.NoResultsError` if the Video does not exist.

  ## Examples

      iex> get_video!(123)
      %Video{}

      iex> get_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_video!(id), do: Repo.get!(Video, id)

  @doc """
  Creates a video.

  ## Examples

      iex> create_video(%{field: value})
      {:ok, %Video{}}

      iex> create_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_video(attrs \\ %{}) do
    %Video{}
    |> Video.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a video.

  ## Examples

      iex> update_video(video, %{field: new_value})
      {:ok, %Video{}}

      iex> update_video(video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a video.

  ## Examples

      iex> delete_video(video)
      {:ok, %Video{}}

      iex> delete_video(video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_video(%Video{} = video) do
    Repo.delete(video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking video changes.

  ## Examples

      iex> change_video(video)
      %Ecto.Changeset{data: %Video{}}

  """
  def change_video(%Video{} = video, attrs \\ %{}) do
    Video.changeset(video, attrs)
  end

  alias DjRumble.Rooms.RoomVideo

  @doc """
  Returns the list of rooms_videos.

  ## Examples

      iex> list_rooms_videos()
      [%RoomVideo{}, ...]

  """
  def list_rooms_videos do
    Repo.all(RoomVideo)
  end

  @doc """
  Gets a single room_video.

  Raises `Ecto.NoResultsError` if the Room video does not exist.

  ## Examples

      iex> get_room_video!(123)
      %RoomVideo{}

      iex> get_room_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room_video!(id), do: Repo.get!(RoomVideo, id)

  @doc """
  Creates a room_video.

  ## Examples

      iex> create_room_video(%{field: value})
      {:ok, %RoomVideo{}}

      iex> create_room_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room_video(attrs \\ %{}) do
    %RoomVideo{}
    |> RoomVideo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room_video.

  ## Examples

      iex> update_room_video(room_video, %{field: new_value})
      {:ok, %RoomVideo{}}

      iex> update_room_video(room_video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room_video(%RoomVideo{} = room_video, attrs) do
    room_video
    |> RoomVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room_video.

  ## Examples

      iex> delete_room_video(room_video)
      {:ok, %RoomVideo{}}

      iex> delete_room_video(room_video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room_video(%RoomVideo{} = room_video) do
    Repo.delete(room_video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room_video changes.

  ## Examples

      iex> change_room_video(room_video)
      %Ecto.Changeset{data: %RoomVideo{}}

  """
  def change_room_video(%RoomVideo{} = room_video, attrs \\ %{}) do
    RoomVideo.changeset(room_video, attrs)
  end

  alias DjRumble.Rooms.UserRoom

  @doc """
  Returns the list of users_rooms.

  ## Examples

      iex> list_users_rooms()
      [%UserRoom{}, ...]

  """
  def list_users_rooms do
    Repo.all(UserRoom)
  end

  @doc """
  Returns the list of users_rooms matching the given params.

  ## Examples

      iex> list_users_rooms()
      [%UserRoom{}, ...]

  """
  def list_users_rooms_by(user_id, is_owner) do
    from(ur in UserRoom,
      where:
        ur.user_id == ^user_id and
          ur.is_owner == ^is_owner
    )
    |> Repo.all()
  end

  @doc """
  Gets a single user_room.

  Raises `Ecto.NoResultsError` if the User room does not exist.

  ## Examples

      iex> get_user_room!(123)
      %UserRoom{}

      iex> get_user_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_room!(id), do: Repo.get!(UserRoom, id)

  @doc """
  Creates a user_room.

  ## Examples

      iex> create_user_room(%{is_owner: value, user_id: value, room_id: value, group_id: value})
      {:ok, %UserRoom{}}

      iex> create_user_room(%{is_owner: bad_value, user_id: bad_value, room_id: bad_value, group_id: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_room(attrs \\ %{}) do
    %UserRoom{}
    |> UserRoom.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:group_id]},
      conflict_target: [:user_id, :room_id]
    )
  end

  @doc """
  Updates a user_room.

  ## Examples

      iex> update_user_room(user_room, %{is_owner: value, user_id: value, room_id: value, group_id: value})
      {:ok, %UserRoom{}}

      iex> update_user_room(user_room, %{is_owner: bad_value, user_id: bad_value, room_id: bad_value, group_id: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_room(%UserRoom{} = user_room, attrs) do
    user_room
    |> UserRoom.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_room.

  ## Examples

      iex> delete_user_room(user_room)
      {:ok, %UserRoom{}}

      iex> delete_user_room(user_room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_room(%UserRoom{} = user_room) do
    Repo.delete(user_room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_room changes.

  ## Examples

      iex> change_user_room(user_room)
      %Ecto.Changeset{data: %UserRoom{}}

  """
  def change_user_room(%UserRoom{} = user_room, attrs \\ %{}) do
    UserRoom.changeset(user_room, attrs)
  end
end
