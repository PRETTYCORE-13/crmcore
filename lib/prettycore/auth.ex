defmodule Prettycore.Auth do
  @moduledoc """
  Módulo de autenticación usando PostgreSQL.
  """
  require Logger

  alias Prettycore.PsqlRepo
  alias Prettycore.Auth.AuthUser

  # Cache simple en memoria para códigos de reset (en producción usar Redis/ETS)
  @reset_codes_table :password_reset_codes

  @doc """
  Autentica un usuario con username y password.
  """
  def authenticate(username, password)
      when is_binary(username) and is_binary(password) do
    case PsqlRepo.get_by(AuthUser, username: username) do
      nil ->
        # Timing attack protection
        Pbkdf2.no_user_verify()
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
    |> PsqlRepo.insert()
  end

  @doc """
  Obtiene un usuario por username.
  """
  def get_user_by_username(username) do
    PsqlRepo.get_by(AuthUser, username: username)
  end

  @doc """
  Obtiene un usuario por ID.
  """
  def get_user(id) do
    PsqlRepo.get(AuthUser, id)
  end

  @doc """
  Lista todos los usuarios.
  """
  def list_users do
    PsqlRepo.all(AuthUser)
  end

  @doc """
  Actualiza un usuario.
  """
  def update_user(%AuthUser{} = user, attrs) do
    user
    |> AuthUser.update_changeset(attrs)
    |> PsqlRepo.update()
  end

  @doc """
  Cambia el password de un usuario.
  """
  def change_password(%AuthUser{} = user, new_password) do
    user
    |> AuthUser.password_changeset(%{password: new_password})
    |> PsqlRepo.update()
  end

  # ============================================================
  # PASSWORD RESET FUNCTIONS
  # ============================================================

  @doc """
  Inicializa la tabla ETS para códigos de reset (llamar en Application.start)
  """
  def init_reset_codes_table do
    if :ets.whereis(@reset_codes_table) == :undefined do
      :ets.new(@reset_codes_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc """
  Solicita un código de reset para el usuario (por email o username).
  """
  def request_reset(identifier) when is_binary(identifier) do
    # Buscar por email o username
    user = get_user_by_email(identifier) || get_user_by_username(identifier)

    case user do
      nil ->
        # Por seguridad, siempre retorna éxito
        {:ok, "Si el usuario existe, recibirás un código"}

      %AuthUser{} = user ->
        if user.email && user.email != "" do
          code = generate_reset_code()
          save_reset_code(user.id, code)

          Logger.info("Reset code generated for user #{user.username}: #{code}")

          # En producción aquí enviarías el email
          # Prettycore.Mailer.send_reset_code(user.email, code)

          {:ok, "Código enviado a #{mask_email(user.email)}. Código: #{code}"}
        else
          {:error, "El usuario no tiene email registrado"}
        end
    end
  end

  @doc """
  Verifica el código y actualiza la contraseña.
  """
  def verify_and_reset(identifier, code, new_password) do
    user = get_user_by_email(identifier) || get_user_by_username(identifier)

    case user do
      nil ->
        {:error, "Usuario no encontrado"}

      %AuthUser{} = user ->
        case verify_reset_code(user.id, code) do
          :ok ->
            case change_password(user, new_password) do
              {:ok, _updated_user} ->
                delete_reset_code(user.id)
                {:ok, "Contraseña actualizada exitosamente"}

              {:error, changeset} ->
                errors = format_changeset_errors(changeset)
                {:error, errors}
            end

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Obtiene un usuario por email.
  """
  def get_user_by_email(email) when is_binary(email) do
    PsqlRepo.get_by(AuthUser, email: email)
  end

  def get_user_by_email(_), do: nil

  # ============================================================
  # PRIVATE FUNCTIONS
  # ============================================================

  defp generate_reset_code do
    :rand.uniform(999_999)
    |> Integer.to_string()
    |> String.pad_leading(6, "0")
  end

  defp save_reset_code(user_id, code) do
    init_reset_codes_table()
    expires_at = System.system_time(:second) + 30 * 60  # 30 minutos
    :ets.insert(@reset_codes_table, {user_id, code, expires_at})
    :ok
  end

  defp verify_reset_code(user_id, code) do
    init_reset_codes_table()
    now = System.system_time(:second)

    case :ets.lookup(@reset_codes_table, user_id) do
      [{^user_id, ^code, expires_at}] when expires_at > now ->
        :ok

      [{^user_id, _other_code, _}] ->
        {:error, "Código inválido"}

      [] ->
        {:error, "Código expirado o no existe"}

      _ ->
        {:error, "Código expirado"}
    end
  end

  defp delete_reset_code(user_id) do
    init_reset_codes_table()
    :ets.delete(@reset_codes_table, user_id)
    :ok
  end

  defp mask_email(email) when is_binary(email) do
    case String.split(email, "@") do
      [name, domain] ->
        masked = if String.length(name) > 2, do: String.slice(name, 0, 2) <> "***", else: "***"
        "#{masked}@#{domain}"
      _ ->
        "***"
    end
  end

  defp mask_email(_), do: "***"

  defp format_changeset_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end
end
