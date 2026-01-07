defmodule Prettycore.Auth do
  @moduledoc false

  alias Prettycore.Repo
  alias Prettycore.Auth.{User, Desencryptor}

  def authenticate(username, password)
      when is_binary(username) and is_binary(password) do
    require Logger

    case Repo.get_by(User, sysusr_codigo_k: username) do
      nil ->
        Desencryptor.decrypt_base64("dummy")
        {:error, :invalid_credentials}

      user ->
        case Desencryptor.decrypt_base64(user.sysusr_password) do
          {:ok, decrypted_password} ->
            # Extraer solo la segunda línea (el password real)
            actual_password =
              decrypted_password
              |> String.split("\n")
              |> Enum.at(1)
              |> String.trim()

            if Plug.Crypto.secure_compare(actual_password, password) do
              {:ok, user}
            else
              {:error, :invalid_credentials}
            end

          {:error, reason} ->
            {:error, :invalid_credentials}
        end
    end
  end
end
