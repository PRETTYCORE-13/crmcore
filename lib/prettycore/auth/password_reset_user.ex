defmodule Prettycore.Auth.PasswordResetUser do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Prettycore.Repo

  @primary_key {:sysusr_codigo_k, :string, source: :SYSUSR_CODIGO_K}

  schema "XEN_SYS_USUARIO" do
    field(:email, :string, source: :SYSUSR_EMAIL)
    field(:s_fecha, :naive_datetime, source: :S_FECHA)
    field(:s_usuario, :string, source: :S_USUARIO)
    field(:password, :string, virtual: true)
  end

  @doc """
  Obtiene usuario con password desde SYS_USUARIO mediante LEFT JOIN
  Retorna {:ok, user} o {:error, :not_found}
  """

  # En password_reset_user.ex

  def get_with_password(sysusr_codigo_k) do
    from(x in "XEN_SYS_USUARIO",
      left_join: s in "SYS_USUARIO",
      on: field(x, :SYSUSR_CODIGO_K) == field(s, :SYSUSR_CODIGO_K),
      where: field(x, :SYSUSR_CODIGO_K) == ^sysusr_codigo_k,
      select: %{
        sysusr_codigo_k: field(x, :SYSUSR_CODIGO_K),
        email: field(x, :SYSUSR_EMAIL),
        password: field(s, :SYSUSR_PASSWORD),
        s_fecha: field(x, :S_FECHA),
        s_usuario: field(x, :S_USUARIO)
      }
    )
    # Esto retorna nil si no encuentra nada
    |> Repo.one()
  end

  @doc """
  Actualiza el password en la tabla SYS_USUARIO
  Retorna {:ok, :updated} o {:error, :not_found}
  """
  def update_password(sysusr_codigo_k, encrypted_password, updated_by) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    query =
      from(s in "SYS_USUARIO",
        # ✅ CORRECTO
        where: field(s, :SYSUSR_CODIGO_K) == ^sysusr_codigo_k
      )

    case Repo.update_all(query,
           set: [
             SYSUSR_PASSWORD: encrypted_password,
             S_FECHA: now,
             S_USUARIO: updated_by
           ]
         ) do
      {1, _} -> {:ok, :updated}
      {0, _} -> {:error, :not_found}
      {n, _} -> {:error, {:multiple_rows_affected, n}}
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
