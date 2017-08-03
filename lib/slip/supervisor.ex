defmodule Slip.Supervisor do
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(Slip.Limiter, []),
      worker(Slip.Web, []),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
