defmodule PrettycoreWeb.PasswordResetController do
  use PrettycoreWeb, :controller

  alias Prettycore.Auth

  @doc """
  POST /api/password-reset/request
  Body: {"email": "usuario@ejemplo.com"} o {"username": "usuario"}
  """
  def request(conn, %{"email" => email}) when is_binary(email) and email != "" do
    do_request(conn, email)
  end

  def request(conn, %{"username" => username}) when is_binary(username) and username != "" do
    do_request(conn, username)
  end

  def request(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "El campo 'email' o 'username' es requerido"
    })
  end

  defp do_request(conn, identifier) do
    case Auth.request_reset(identifier) do
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
          error: reason
        })
    end
  end

  @doc """
  POST /api/password-reset/verify
  Body: {
    "email": "usuario@ejemplo.com", (o "username": "usuario")
    "code": "123456",
    "new_password": "NuevaPassword123"
  }
  """
  def verify(conn, %{"code" => code, "new_password" => password} = params)
      when is_binary(code) and is_binary(password) do
    identifier = params["email"] || params["username"]

    if is_nil(identifier) or identifier == "" do
      conn
      |> put_status(:bad_request)
      |> json(%{
        success: false,
        error: "El campo 'email' o 'username' es requerido"
      })
    else
      case validate_password(password) do
        :ok ->
          case Auth.verify_and_reset(identifier, code, password) do
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
                error: reason
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
  end

  def verify(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "Los campos 'email' (o 'username'), 'code' y 'new_password' son requeridos"
    })
  end

  # Validación de contraseña
  defp validate_password(password) do
    cond do
      String.length(password) < 6 ->
        {:error, "La contraseña debe tener al menos 6 caracteres"}

      true ->
        :ok
    end
  end
end
