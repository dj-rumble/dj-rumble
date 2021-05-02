defmodule DjRumble.Accounts.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias Faker

  @derive {Inspect, except: [:password]}
  schema "users" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime

    many_to_many :rooms, DjRumble.Rooms.Room, join_through: DjRumble.Rooms.UserRoom
    # many_to_many :videos, DjRumble.Rooms.Video, join_through: DjRumble.Rooms.UserVideo

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_username()
    |> validate_email()
    |> validate_password()
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 24)
    |> unsafe_validate_unique(:username, DjRumble.Repo)
    |> unique_constraint(:username)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, DjRumble.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 80)
    |> prepare_changes(&hash_password/1)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    changeset
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  end

  @doc """
  A user changeset for changing the username.

  It requires the username to change otherwise an error is added.
  """
  def username_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> update_change(:username, &remove_spaces/1)
    |> validate_username()
    |> case do
      %{changes: %{username: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :username, "did not change")
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password()
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%DjRumble.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  defp remove_spaces(username) do
    case username do
      nil -> username
      _ -> String.replace(String.trim(username), ~r/\s+/, " ")
    end
  end

  def create_random_name do
    adjectives = [
      fn -> Faker.Superhero.descriptor() end,
      fn -> Faker.Pizza.cheese() end,
      fn -> Faker.Pizza.style() end,
      fn -> Faker.Commerce.product_name_material() end,
      fn -> Faker.Cannabis.strain() end,
      fn -> Faker.Commerce.product_name_adjective() end
    ]

    nouns = [
      fn -> Faker.StarWars.character() end,
      fn -> Faker.Pokemon.name() end,
      fn -> Faker.Food.ingredient() end,
      fn -> Faker.Superhero.name() end
    ]

    descriptor = Enum.at(adjectives, Enum.random(0..(length(adjectives) - 1)))
    name = Enum.at(nouns, Enum.random(0..(length(nouns) - 1)))
    "#{descriptor.()} #{name.()}"
  end
end
