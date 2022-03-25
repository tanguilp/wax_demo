defmodule WaxDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WaxDemoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: WaxDemo.PubSub},
      # Start the Endpoint (http/https)
      WaxDemoWeb.Endpoint
      # Start a worker by calling: WaxDemo.Worker.start_link(arg)
      # {WaxDemo.Worker, arg}
    ]

    :ets.new(:wax_session, [:named_table, :public, read_concurrency: true])

    WaxDemo.User.init()

    opts = [strategy: :one_for_one, name: WaxDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WaxDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
