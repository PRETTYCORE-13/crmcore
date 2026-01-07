defmodule Prettycore.Auth.PasswordReset do
  require Logger
  alias Prettycore.Emails.PasswordReset, as: PasswordResetEmail
  alias Prettycore.Repo
  alias Prettycore.Auth.PasswordResetUser, as: User
  alias Prettycore.Auth.Encryptor, as: Crypto
  alias Prettycore.Auth.Desencryptor

  @doc """
  Solicita reset por código de usuario (SYSUSR_CODIGO_K)
  """
  def request_reset_by_username(username) when is_binary(username) do
    code = generate_code()

    case User.get_with_password(username) do
      nil ->
        # Por seguridad, siempre retorna éxito
        {:ok, "Si el usuario existe, recibirás un código en tu email"}

      user ->
        if is_nil(user.email) or user.email == "" do
          {:error, "El usuario no tiene un email registrado"}
        else
          with :ok <- save_reset_token(user.sysusr_codigo_k, code),
               {:ok, _} <-
                 PasswordResetEmail.send_reset_code(
                   user.email,
                   user.sysusr_codigo_k,
                   code
                 ) do
            {:ok, "Código enviado exitosamente a #{mask_email(user.email)}"}
          else
            {:error, reason} ->
              Logger.error("Error al enviar código: #{inspect(reason)}")
              {:error, "No se pudo enviar el código. Intenta nuevamente."}
          end
        end
    end
  end

  @doc """
  Verifica código y actualiza contraseña
  """
  def verify_and_reset(username, code, new_password) do
    with user when not is_nil(user) <- User.get_with_password(username),
         :ok <- verify_code(user.sysusr_codigo_k, code),
         {:ok, _count} <- update_password(user, new_password) do
      mark_token_as_used(user.sysusr_codigo_k, code)
      {:ok, "Contraseña actualizada exitosamente"}
    else
      nil ->
        {:error, "Usuario no encontrado"}

      {:error, :invalid_code} ->
        {:error, "Código inválido o expirado"}

      {:error, reason} ->
        Logger.error("Error en verify_and_reset: #{inspect(reason)}")
        {:error, "No se pudo actualizar la contraseña"}
    end
  end

  # ============================================================
  # FUNCIONES PRIVADAS
  # ============================================================

  defp generate_code do
    :rand.uniform(999_999)
    |> Integer.to_string()
    |> String.pad_leading(6, "0")
  end

  defp save_reset_token(user_codigo, code) do
    expires_at = DateTime.add(DateTime.utc_now(), 30 * 60, :second)
    hashed_code = hash_code(code)

    Logger.info("✓ Token generado - Usuario: #{user_codigo}, Código: #{code}")
    Logger.debug("Hash del token: #{hashed_code}")
    Logger.debug("Expira en: #{DateTime.to_string(expires_at)}")

    # TODO: Guarda en tabla de tokens si la tienes
    # PasswordResetToken.create(%{
    #   user_codigo: user_codigo,
    #   token: hashed_code,
    #   expires_at: expires_at,
    #   used: false
    # })

    :ok
  end

  defp hash_code(code) do
    :crypto.hash(:sha256, code) |> Base.encode16()
  end

  defp verify_code(user_codigo, code) do
    hashed_code = hash_code(code)

    Logger.info("✓ Verificando código - Usuario: #{user_codigo}")
    Logger.debug("Código recibido: #{code}")
    Logger.debug("Hash calculado: #{hashed_code}")

    # TODO: Verifica contra la tabla de tokens
    # now = DateTime.utc_now()
    #
    # query = from t in PasswordResetToken,
    #   where: t.user_codigo == ^user_codigo,
    #   where: t.token == ^hashed_code,
    #   where: t.used == false,
    #   where: t.expires_at > ^now
    #
    # case Repo.one(query) do
    #   nil -> {:error, :invalid_code}
    #   _token -> :ok
    # end

    # Por ahora acepta cualquier código (SOLO PARA DESARROLLO)
    :ok
  end

  defp update_password(user, new_password) do
    Logger.info("Actualizando password para usuario: #{user.sysusr_codigo_k}")

    # 1. Desencripta password actual y construye el nuevo formato
    result =
      if user.password do
        case Desencryptor.decrypt_base64(user.password) do
          {:ok, old_password_content} ->
            Logger.info("✓ Password anterior desencriptado correctamente")
            Logger.debug("Contenido desencriptado: #{inspect(old_password_content)}")

            # Reemplaza la segunda línea preservando el formato
            updated_content = replace_second_line(old_password_content, new_password)
            Logger.info("✓ Contenido actualizado con nueva password")
            Logger.debug("Nuevo contenido: #{inspect(updated_content)}")

            # Encripta el contenido completo actualizado
            # OPCIÓN 1: Si tu Encryptor tiene un método encrypt/1
            case Crypto.encrypt(updated_content) do
              {:ok, encrypted} ->
                {:ok, encrypted}

              encrypted when is_binary(encrypted) ->
                {:ok, encrypted}

              error ->
                Logger.error("Error encriptando: #{inspect(error)}")
                {:error, "Error al encriptar"}
            end

          {:error, reason} ->
            Logger.warn("⚠ No se pudo desencriptar password anterior: #{reason}")
            Logger.info("Creando nuevo formato de password")
            # Si no se puede desencriptar, crea nuevo formato
            case Crypto.encrypt("\n#{new_password}\n") do
              {:ok, encrypted} -> {:ok, encrypted}
              encrypted when is_binary(encrypted) -> {:ok, encrypted}
              error -> {:error, "Error al encriptar: #{inspect(error)}"}
            end
        end
      else
        Logger.warn("⚠ Usuario no tiene password en SYS_USUARIO, creando nuevo")

        case Crypto.encrypt("\n#{new_password}\n") do
          {:ok, encrypted} -> {:ok, encrypted}
          encrypted when is_binary(encrypted) -> {:ok, encrypted}
          error -> {:error, "Error al encriptar: #{inspect(error)}"}
        end
      end

    case result do
      {:ok, new_encrypted_content} ->
        Logger.info("✓ Nueva password encriptada")

        Logger.debug(
          "Password encriptado (primeros 20 chars): #{String.slice(new_encrypted_content, 0, 20)}..."
        )

        # 2. Actualiza en SYS_USUARIO
        case User.update_password(
               user.sysusr_codigo_k,
               new_encrypted_content,
               user.sysusr_codigo_k
             ) do
          {:ok, :updated} ->
            Logger.info("✓ Password actualizado exitosamente en BD")
            {:ok, 1}

          {1, _} ->
            Logger.info("✓ Password actualizado exitosamente en BD")
            {:ok, 1}

          {:ok, _} ->
            Logger.info("✓ Password actualizado exitosamente en BD")
            {:ok, 1}

          {0, _} ->
            Logger.error("✗ No se encontró el registro en SYS_USUARIO")
            {:error, "Usuario no encontrado en SYS_USUARIO"}

          {:error, reason} ->
            Logger.error("✗ Error al actualizar: #{inspect(reason)}")
            {:error, "Error al actualizar en base de datos"}

          error ->
            Logger.error("✗ Respuesta inesperada al actualizar: #{inspect(error)}")
            {:error, "Error al actualizar en base de datos"}
        end

      {:error, reason} ->
        Logger.error("✗ Error en encriptación: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp replace_second_line(content, new_password) do
    content
    |> String.split("\n", trim: false)
    |> List.replace_at(1, new_password)
    |> Enum.join("\n")
  end

  defp mark_token_as_used(user_codigo, _code) do
    Logger.info("✓ Token marcado como usado: #{user_codigo}")

    # TODO: Actualiza el token en BD
    # hashed_code = hash_code(code)
    # from(t in PasswordResetToken,
    #   where: t.user_codigo == ^user_codigo,
    #   where: t.token == ^hashed_code
    # )
    # |> Repo.update_all(set: [used: true])

    :ok
  end

  defp mask_email(email) when is_binary(email) do
    case String.split(email, "@") do
      [name, domain] ->
        masked_name =
          if String.length(name) > 3 do
            String.slice(name, 0, 2) <> "***"
          else
            "***"
          end

        "#{masked_name}@#{domain}"

      _ ->
        "***"
    end
  end

  defp mask_email(_), do: "***"
end
