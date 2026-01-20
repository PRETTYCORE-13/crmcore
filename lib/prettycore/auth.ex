defmodule Prettycore.Auth do
  @moduledoc """
  Módulo de autenticación usando PostgreSQL.
  """

  alias Prettycore.AuthRepo
  alias Prettycore.Auth.AuthUser

  @doc """
  Autentica un usuario con username y password.
  """
  def authenticate(username, password)
      when is_binary(username) and is_binary(password) do
    case AuthRepo.get_by(AuthUser, username: username) do
      nil ->
        # Timing attack protection
        AuthUser.verify_password(%AuthUser{password_hash: "dummy"}, "dummy")
        {:error, :invalid_credentials}

      user ->
        if user.active && AuthUser.verify_password(user, password) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Crea un nuevo usuario.
  """
  def create_user(attrs) do
    %AuthUser{}
    |> AuthUser.changeset(attrs)
    |> AuthRepo.insert()
  end

  @doc """
  Obtiene un usuario por username.
  """
  def get_user_by_username(username) do
    AuthRepo.get_by(AuthUser, username: username)
  end

  @doc """
  Obtiene un usuario por ID.
  """
  def get_user(id) do
    AuthRepo.get(AuthUser, id)
  end

  @doc """
  Lista todos los usuarios.
  """
  def list_users do
    AuthRepo.all(AuthUser)
  end

  @doc """
  Actualiza un usuario.
  """
  def update_user(%AuthUser{} = user, attrs) do
    user
    |> AuthUser.update_changeset(attrs)
    |> AuthRepo.update()
  end

  @doc """
  Cambia el password de un usuario.
  """
  def change_password(%AuthUser{} = user, new_password) do
    user
    |> AuthUser.password_changeset(%{password: new_password})
    |> AuthRepo.update()
  end
end
