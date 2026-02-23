defmodule Prettycore.SysAdmin do
  @moduledoc """
  Contexto para la configuración global del sistema (SYSADMIN).
  Singleton: siempre usa id=1.
  """

  alias Prettycore.PsqlRepo
  alias Prettycore.SysAdmin.Config

  @singleton_id 1
  @default_instancia "https://s2.ecore.ninja:1522/SP/EN_RESTHELPER"
  @default_token "IFcRzSfaBG6ycnpWzThyfEdKHglK14tlZylvRhOhlQ1fDHobmveKk6JowcU/BhCquBlqQv7zkrLIUYvFZmQZqHdqNiLptzCBf5wT826XpY4="

  def get_config do
    case PsqlRepo.get(Config, @singleton_id) do
      nil ->
        %Config{
          id: @singleton_id,
          usuario: "",
          instancia: @default_instancia,
          token: @default_token,
          url: "",
          foto: ""
        }
      config -> config
    end
  end

  def save_config(attrs) do
    case PsqlRepo.get(Config, @singleton_id) do
      nil ->
        %Config{id: @singleton_id}
        |> Config.changeset(attrs)
        |> PsqlRepo.insert()
      config ->
        config
        |> Config.changeset(attrs)
        |> PsqlRepo.update()
    end
  end
end
