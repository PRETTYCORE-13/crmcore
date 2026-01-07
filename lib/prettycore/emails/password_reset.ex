defmodule Prettycore.Emails.PasswordReset do
  import Swoosh.Email
  require Logger
  alias Prettycore.Mailer

  @from_email "servicios.ennovacore@gmail.com"
  @from_name "Sistema - EnnovaCore"
  @token_expiry_minutes 30

  def send_reset_code(user_email, user_name, code) do
    email_struct =
      new()
      |> to({user_name || user_email, user_email})
      |> from({@from_name, @from_email})
      |> subject("Código de Verificación - Cambio de Contraseña")
      |> html_body(html_template(user_name, code))
      |> text_body(text_template(user_name, code))

    case Mailer.deliver(email_struct) do
      {:ok, response} ->
        Logger.info("Email enviado correctamente: #{inspect(response)}")
        {:ok, response}

      {:error, reason} ->
        Logger.error("Error al enviar email: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp html_template(user_name, code) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">

          <h2 style="color: #2c3e50;">Cambio de Contraseña</h2>

          <p>Hola <strong>#{user_name}</strong>,</p>

          <p>Recibimos una solicitud para cambiar tu contraseña. Utiliza el siguiente código:</p>

          <div style="background-color: #f8f9fa; border: 2px solid #4CAF50; border-radius: 8px; padding: 20px; margin: 25px 0; text-align: center;">
            <span style="font-size: 36px; font-weight: bold; letter-spacing: 10px; color: #2c3e50;">#{code}</span>
          </div>

          <p style="color: #e74c3c; font-weight: bold;">⚠️ Este código expira en #{@token_expiry_minutes} minutos.</p>

          <p style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
            Si no solicitaste este cambio, ignora este mensaje.
          </p>

          <div style="margin-top: 20px; font-size: 12px; color: #999;">
            <p>Fecha: #{format_datetime()}</p>
          </div>

        </div>
      </div>
    </body>
    </html>
    """
  end

  defp text_template(user_name, code) do
    """
    CAMBIO DE CONTRASEÑA

    Hola #{user_name},

    Tu código de verificación es: #{code}

    ⚠️ Este código expira en #{@token_expiry_minutes} minutos.

    Si no solicitaste este cambio, ignora este mensaje.

    Fecha: #{format_datetime()}
    """
  end

  defp format_datetime do
    DateTime.utc_now()
    |> Calendar.strftime("%d/%m/%Y %H:%M:%S UTC")
  end
end
