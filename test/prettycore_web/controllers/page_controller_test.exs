defmodule PrettycoreWeb.PageControllerTest do
  use PrettycoreWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Iniciar sesión"
  end
end
