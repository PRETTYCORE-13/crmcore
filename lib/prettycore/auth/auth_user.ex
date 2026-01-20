defmodule Prettycore.Auth.AuthUser do
  @moduledoc """
  Schema de usuario para autenticación con PostgreSQL.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :active, :boolean, default: true
    field :role, :string, default: "user"

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset para crear un nuevo usuario.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :active, :role])
    |> validate_required([:username, :password])
    |> validate_length(:username, min: 3, max: 50)
    |> validate_length(:password, min: 6)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "debe ser un email válido")
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> hash_password()
  end

  @doc """
  Changeset para actualizar usuario (sin cambiar password).
  """
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :active, :role])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "debe ser un email válido")
    |> unique_constraint(:email)
  end

  @doc """
  Changeset para cambiar password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6)
    |> hash_password()
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        # Hash simple con Base64 (compatible con tu sistema actual)
        # En producción deberías usar Bcrypt o Argon2
        hash = Base.encode64(password)
        put_change(changeset, :password_hash, hash)
    end
  end

  @doc """
  Verifica si el password coincide.
  """
  def verify_password(user, password) do
    Base.encode64(password) == user.password_hash
  end
end
