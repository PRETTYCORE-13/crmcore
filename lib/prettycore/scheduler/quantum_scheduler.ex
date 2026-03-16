defmodule Prettycore.Scheduler.QuantumScheduler do
  @moduledoc """
  Motor de cron jobs basado en Quantum.
  Las tareas dinámicas son cargadas por DynamicScheduler al arrancar.
  """
  use Quantum, otp_app: :prettycore
end
