defmodule PrettycoreWeb.LiveCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require testing LiveViews.

  Such tests rely on `Phoenix.LiveViewTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint PrettycoreWeb.Endpoint

      use PrettycoreWeb, :verified_routes

      # Import conveniences for testing with LiveViews
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import PrettycoreWeb.LiveCase
    end
  end

  setup tags do
    conn = Phoenix.ConnTest.build_conn()

    # Add session if authenticated test
    conn = if tags[:authenticated] do
      Plug.Test.init_test_session(conn, %{
        "user_id" => "test_user_id",
        "user_email" => "test@example.com"
      })
    else
      conn
    end

    {:ok, conn: conn}
  end
end
