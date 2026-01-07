defmodule Prettycore.Auth.User do
  use Ecto.Schema

  @primary_key false
  schema "SYS_USUARIO" do
    field(:sysusr_codigo_k, :string, source: :SYSUSR_CODIGO_K)
    field(:sysusr_password, :string, source: :SYSUSR_PASSWORD)
  end
end
