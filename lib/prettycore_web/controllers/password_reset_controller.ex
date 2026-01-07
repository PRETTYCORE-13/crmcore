# apps/prettycore_web/lib/prettycore_web/controllers/password_reset_controller.ex
defmodule PrettycoreWeb.PasswordResetController do
  use PrettycoreWeb, :controller
  alias Prettycore.Auth.PasswordReset

  @doc """
  POST /api/password-reset/request
  Body: {"email": "usuario@ejemplo.com"}
  """
  def request(conn, %{"email" => email}) when is_binary(email) do
    case PasswordReset.request_reset(email) do
      {:ok, message} ->
        json(conn, %{
          success: true,
          message: message
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: to_string(reason)
        })
    end
  end

  def request(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "El campo 'email' es requerido"
    })
  end

  @doc """
  POST /api/password-reset/verify
  Body: {
    "email": "usuario@ejemplo.com",
    "code": "123456",
    "new_password": "NuevaPassword123!"
  }
  """
  def verify(conn, %{"email" => email, "code" => code, "new_password" => password})
      when is_binary(email) and is_binary(code) and is_binary(password) do
    # Valida que la contraseña cumpla requisitos mínimos
    case validate_password(password) do
      :ok ->
        case PasswordReset.verify_and_reset(email, code, password) do
          {:ok, message} ->
            json(conn, %{
              success: true,
              message: message
            })

          {:error, reason} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              success: false,
              error: to_string(reason)
            })
        end

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: reason
        })
    end
  end

  def verify(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "Los campos 'email', 'code' y 'new_password' son requeridos"
    })
  end

  # Validación de contraseña
  defp validate_password(password) do
    cond do
      String.length(password) < 8 ->
        {:error, "La contraseña debe tener al menos 8 caracteres"}

      not Regex.match?(~r/[A-Z]/, password) ->
        {:error, "La contraseña debe contener al menos una mayúscula"}

      not Regex.match?(~r/[a-z]/, password) ->
        {:error, "La contraseña debe contener al menos una minúscula"}

      not Regex.match?(~r/[0-9]/, password) ->
        {:error, "La contraseña debe contener al menos un número"}

      true ->
        :ok
    end
  end
end
