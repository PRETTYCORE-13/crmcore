defmodule Prettycore.DataCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require database access.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Prettycore.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Prettycore.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Prettycore.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
