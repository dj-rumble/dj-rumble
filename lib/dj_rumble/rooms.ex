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
      [%DjRumble.Rooms.Room{}]

  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %DjRumble.Rooms.Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  @doc """
  Gets a single room by slug.

  Raises `Ecto.NoResultsError` if the User room does not exist.

  ## Examples

      iex> get_room_by_slug(1)
      %DjRumble.Rooms.Room{slug: 1}

      iex> get_room_by_slug("1")
      ** nil

  """
  def get_room_by_slug(slug) do
    Repo.get_by(Room, %{slug: slug})
  end

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{name: "some name"})
      {:ok, %DjRumble.Rooms.Room{name: "some name"}}

      iex> create_room(%{name: 123})
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

      iex> update_room(%DjRumble.Rooms.Room{}, %{name: "some name"})
      {:ok, %DjRumble.Rooms.Room{}}

      iex> update_room(%DjRumble.Rooms.Room{}, %{name: 123})
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

      iex> delete_room(%DjRumble.Rooms.Room{})
      {:ok, %DjRumble.Rooms.Room{}}

      iex> delete_room(nil)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(%DjRumble.Rooms.Room{}, %{})
      %Ecto.Changeset{data: %DjRumble.Rooms.Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  @doc """
  Returns a preloaded `%Room{}`.

  ## Examples

      iex> preload_room(%DjRumble.Rooms.Room{}, [])
      %DjRumble.Rooms.Room{}

  """
  def preload_room(%Room{} = room, attrs \\ []) do
    Repo.preload(room, attrs)
  end

  alias DjRumble.Rooms.Video

  @doc """
  Returns the list of videos.

  ## Examples

      iex> list_videos()
      [%DjRumble.Rooms.Video{}]

  """
  def list_videos do
    Repo.all(Video)
  end

  @doc """
  Gets a single video.

  Raises `Ecto.NoResultsError` if the Video does not exist.

  ## Examples

      iex> get_video!(123)
      %DjRumble.Rooms.Video{}

      iex> get_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_video!(id), do: Repo.get!(Video, id)

  @doc """
  Creates a video.

  ## Examples

      iex> create_video(%{video_id: "asd123"})
      {:ok, %DjRumble.Rooms.Video{video_id: "asd123"}}

      iex> create_video(%{video_id: 123})
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

      iex> update_video(%DjRumble.Rooms.Video{}, %{title: "some title"})
      {:ok, %DjRumble.Rooms.Video{title: "some title"}}

      iex> update_video(%DjRumble.Rooms.Video{}, %{title: "some title"})
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

      iex> delete_video(%DjRumble.Rooms.Video{})
      {:ok, %DjRumble.Rooms.Video{}}

      iex> delete_video(nil)
      {:error, %Ecto.Changeset{}}

  """
  def delete_video(%Video{} = video) do
    Repo.delete(video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking video changes.

  ## Examples

      iex> change_video(%DjRumble.Rooms.Video{title: "some title"})
      %Ecto.Changeset{data: %DjRumble.Rooms.Video{title: "some title"}}

  """
  def change_video(%Video{} = video, attrs \\ %{}) do
    Video.changeset(video, attrs)
  end

  alias DjRumble.Rooms.RoomVideo

  @doc """
  Returns the list of rooms_videos.

  ## Examples

      iex> list_rooms_videos()
      [%DjRumble.Rooms.RoomVideo{}]

  """
  def list_rooms_videos do
    Repo.all(RoomVideo)
  end

  @doc """
  Gets a single room_video.

  Raises `Ecto.NoResultsError` if the Room video does not exist.

  ## Examples

      iex> get_room_video!(123)
      %DjRumble.Rooms.RoomVideo{}

      iex> get_room_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room_video!(id), do: Repo.get!(RoomVideo, id)

  @doc """
  Creates a room_video.

  ## Examples

      iex> create_room_video(%{video_id: "asd123})
      {:ok, %DjRumble.Rooms.RoomVideo{video_id: "asd123"}}

      iex> create_room_video(%{video_id: 123})
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

      iex> update_room_video(%DjRumble.Rooms.RoomVideo{}, %{video_id: 1})
      {:ok, %DjRumble.Rooms.RoomVideo{}}

      iex> update_room_video(%DjRumble.Rooms.RoomVideo{}, %{video_id: "1"})
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

      iex> delete_room_video(%DjRumble.Rooms.RoomVideo{})
      {:ok, %DjRumble.Rooms.RoomVideo{}}

      iex> delete_room_video(nil)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room_video(%RoomVideo{} = room_video) do
    Repo.delete(room_video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room_video changes.

  ## Examples

      iex> change_room_video(DjRumble.Rooms.RoomVideo{room_id: 1}, %{room_id: 2})
      %Ecto.Changeset{data: %DjRumble.Rooms.RoomVideo{room_id: 2}}

  """
  def change_room_video(%RoomVideo{} = room_video, attrs \\ %{}) do
    RoomVideo.changeset(room_video, attrs)
  end

  alias DjRumble.Rooms.UserRoom

  @doc """
  Returns the list of users_rooms.

  ## Examples

      iex> list_users_rooms()
      [%DjRumble.Rooms.UserRoom{}]

  """
  def list_users_rooms do
    Repo.all(UserRoom)
  end

  @doc """
  Gets a single user_room.

  Raises `Ecto.NoResultsError` if the User room does not exist.

  ## Examples

      iex> get_user_room!(1)
      %DjRumble.Rooms.UserRoom{}

      iex> get_user_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_room!(id), do: Repo.get!(UserRoom, id)

  @doc """
  Deletes a user_room.

  ## Examples

      iex> delete_user_room(%DjRumble.Rooms.UserRoom{})
      {:ok, %DjRumble.Rooms.UserRoom{}}

      iex> delete_user_room(nil)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_room(%UserRoom{} = user_room) do
    Repo.delete(user_room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_room changes.

  ## Examples

      iex> change_user_room(DjRumble.Rooms.UserRoom{user_id: 1}, %{user_id: 2})
      %Ecto.Changeset{data: %DjRumble.Rooms.UserRoom{user_id: 2}}

  """
  def change_user_room(%UserRoom{} = user_room, attrs \\ %{}) do
    UserRoom.changeset(user_room, attrs)
  end
end
