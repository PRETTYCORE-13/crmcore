defmodule Prettycore.Auth.PasswordResetUser do
  @moduledoc """
  Módulo para gestión de usuarios en reset de password usando API REST EN_RESTHELPER.

  Este módulo consume datos desde la API REST en lugar de
  consultas directas a SQL Server.

  Base URL: http://ecore.ath.cx:1405/SP/EN_RESTHELPER/
  """

  alias Prettycore.Api.Client, as: Api

  @doc """
  Obtiene usuario con password desde SYS_USUARIO mediante API.
  Retorna un map con los datos del usuario o nil si no existe.
  """
  def get_with_password(sysusr_codigo_k) do
    # Primero obtener datos de XEN_SYS_USUARIO
    with {:ok, xen_user} <- get_xen_usuario(sysusr_codigo_k),
         {:ok, sys_user} <- get_sys_usuario(sysusr_codigo_k) do
      %{
        sysusr_codigo_k: xen_user["SYSUSR_CODIGO_K"],
        email: xen_user["SYSUSR_EMAIL"],
        password: sys_user["SYSUSR_PASSWORD"],
        s_fecha: parse_datetime(xen_user["S_FECHA"]),
        s_usuario: xen_user["S_USUARIO"]
      }
    else
      {:error, :not_found} ->
        # Intentar solo con XEN si SYS no existe
        case get_xen_usuario(sysusr_codigo_k) do
          {:ok, xen_user} ->
            %{
              sysusr_codigo_k: xen_user["SYSUSR_CODIGO_K"],
              email: xen_user["SYSUSR_EMAIL"],
              password: nil,
              s_fecha: parse_datetime(xen_user["S_FECHA"]),
              s_usuario: xen_user["S_USUARIO"]
            }

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  defp get_xen_usuario(codigo) do
    case Api.get_xen_usuario(codigo, Api.service_token()) do
      {:ok, user} when is_map(user) -> {:ok, user}
      {:ok, [user | _]} -> {:ok, user}
      {:ok, []} -> {:error, :not_found}
      {:error, _} -> {:error, :not_found}
    end
  end

  defp get_sys_usuario(codigo) do
    case Api.get_usuario(codigo, Api.service_token()) do
      {:ok, user} when is_map(user) -> {:ok, user}
      {:ok, [user | _]} -> {:ok, user}
      {:ok, []} -> {:error, :not_found}
      {:error, _} -> {:error, :not_found}
    end
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case NaiveDateTime.from_iso8601(datetime_string) do
      {:ok, dt} -> dt
      {:error, _} -> nil
    end
  end
  defp parse_datetime(%NaiveDateTime{} = dt), do: dt
  defp parse_datetime(_), do: nil

  @doc """
  Actualiza el password en la tabla SYS_USUARIO vía API.
  Retorna {:ok, :updated} o {:error, :not_found}
  """
  def update_password(sysusr_codigo_k, encrypted_password, updated_by) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    data = %{
      "SYSUSR_CODIGO_K" => sysusr_codigo_k,
      "SYSUSR_PASSWORD" => encrypted_password,
      "S_FECHA" => NaiveDateTime.to_iso8601(now),
      "S_USUARIO" => updated_by
    }

    case Api.update("SYS_USUARIO", data, Api.service_token()) do
      {:ok, _} ->
        {:ok, :updated}

      {:error, {:http_error, 404, _}} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Valida que el usuario tenga un email válido para reseteo
  """
  def validate_for_reset(user) do
    cond do
      is_nil(user.email) or user.email == "" ->
        {:error, :email_no_configurado}

      is_nil(user.password) ->
        {:error, :usuario_sin_password}

      true ->
        {:ok, user}
    end
  end
end
