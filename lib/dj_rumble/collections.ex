defmodule DjRumble.Collections do
  @moduledoc """
  The Collections context.
  """

  import Ecto.Query, warn: false
  alias DjRumble.Repo

  alias DjRumble.Collections.UserVideo

  @doc """
  Returns the list of users_videos.

  ## Examples

      iex> list_users_videos()
      [%UserVideo{}, ...]

  """
  def list_users_videos do
    Repo.all(UserVideo)
  end

  @doc """
  Gets a single user_video.

  Raises `Ecto.NoResultsError` if the User video does not exist.

  ## Examples

      iex> get_user_video!(123)
      %UserVideo{}

      iex> get_user_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_video!(id), do: Repo.get!(UserVideo, id)

  @doc """
  Creates a user_video.

  ## Examples

      iex> create_user_video(%{field: value})
      {:ok, %UserVideo{}}

      iex> create_user_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_video(attrs \\ %{}) do
    %UserVideo{}
    |> UserVideo.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Updates a user_video.

  ## Examples

      iex> update_user_video(user_video, %{field: new_value})
      {:ok, %UserVideo{}}

      iex> update_user_video(user_video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_video(%UserVideo{} = user_video, attrs) do
    user_video
    |> UserVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_video.

  ## Examples

      iex> delete_user_video(user_video)
      {:ok, %UserVideo{}}

      iex> delete_user_video(user_video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_video(%UserVideo{} = user_video) do
    Repo.delete(user_video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_video changes.

  ## Examples

      iex> change_user_video(user_video)
      %Ecto.Changeset{data: %UserVideo{}}

  """
  def change_user_video(%UserVideo{} = user_video, attrs \\ %{}) do
    UserVideo.changeset(user_video, attrs)
  end
end
