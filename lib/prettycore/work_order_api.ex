defmodule Prettycore.WorkorderApi do
  @moduledoc false

  @url "http://ecore.ath.cx:1405/SP/EN_RESTHELPER/workorderEstado"

  # estado: 1 = aceptar, 0 = rechazar
  # AHORA RECIBE TAMBIÉN EL password DEL SELECT
  def cambiar_estado(ref, estado, password) when estado in [0, 1] do
    body = %{
      "WOKE_REFERENCIA" => ref,
      "Estado" => Integer.to_string(estado)
      # Si quieres también mandar el password en el body, lo agregas aquí:
      # "SYSUSR_PASSWORD" => password
    }

    headers = [
      # En lugar de token fijo, mandas el password
      {"authorization", "Bearer " <> password},
      {"content-type", "application/json"}
    ]

    case Req.post(@url, json: body, headers: headers) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        IO.inspect(body, label: " error body")
        IO.inspect(resp_body, label: "workorderEstado error body")
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
