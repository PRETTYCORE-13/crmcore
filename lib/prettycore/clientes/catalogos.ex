defmodule Prettycore.Clientes.PatronFrecuencia do
  use Ecto.Schema

  @primary_key {:ctepfr_codigo_k, :string, autogenerate: false}
  schema "CTE_PATRONFREC" do
    field(:ctepfr_descipcion, :string)
  end
end

defmodule Prettycore.Clientes.Canal do
  use Ecto.Schema

  @primary_key {:ctecan_codigo_k, :string, autogenerate: false}
  schema "CTE_CANAL" do
    field(:ctecan_descripcion, :string)
  end
end

defmodule Prettycore.Clientes.Subcanal do
  use Ecto.Schema

  @primary_key false
  schema "CTE_SUBCANAL" do
    field(:ctecan_codigo_k, :string, primary_key: true)
    field(:ctesca_codigo_k, :string, primary_key: true)
    field(:ctesca_descripcion, :string)
  end
end

defmodule Prettycore.Clientes.Cadena do
  use Ecto.Schema

  @primary_key {:ctecad_codigo_k, :string, autogenerate: false}
  schema "CTE_CADENA" do
    field(:ctecad_dcomercial, :string)
  end
end

defmodule Prettycore.Clientes.PaqueteServicio do
  use Ecto.Schema

  @primary_key {:ctepaq_codigo_k, :string, autogenerate: false}
  schema "CTE_PAQUETESERV" do
    field(:ctepaq_descripcion, :string)
  end
end

defmodule Prettycore.Clientes.Regimen do
  use Ecto.Schema

  @primary_key {:ctereg_codigo_k, :string, autogenerate: false}
  schema "CTE_REGIMEN" do
    field(:ctereg_descripcion, :string)
  end
end

defmodule Prettycore.Clientes.Estado do
  use Ecto.Schema

  @primary_key {:mapedo_codigo_k, :integer, autogenerate: false}
  schema "MAP_ESTADO" do
    field(:mapedo_descripcion, :string)
  end
end

defmodule Prettycore.Clientes.Municipio do
  use Ecto.Schema

  @primary_key false
  schema "MAP_MUNICIPIO" do
    field(:mapedo_codigo_k, :integer, primary_key: true)
    field(:mapmun_codigo_k, :integer, primary_key: true)
    field(:mapmun_descripcion, :string)
  end
end

defmodule Prettycore.Clientes.Localidad do
  use Ecto.Schema

  @primary_key false
  schema "MAP_LOCALIDAD" do
    field(:mapedo_codigo_k, :integer, primary_key: true)
    field(:mapmun_codigo_k, :integer, primary_key: true)
    field(:maploc_codigo_k, :integer, primary_key: true)
    field(:maploc_descripcion, :string)
  end
end

defmodule Prettycore.Clientes.Ruta do
  use Ecto.Schema

  @primary_key {:vtarut_codigo_k, :string, autogenerate: false}
  schema "VTA_RUTA" do
    field(:sysudn_codigo_k, :string)
  end
end
