defmodule PrettycoreWeb.AccessOkLive do
  use PrettycoreWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="pc-login-wrap">
      <div class="pc-login-card">
        <h1>Acceso exitoso</h1>

        <p>Ya puedes usar el sistema.</p>
      </div>
    </div>
    """
  end
end
