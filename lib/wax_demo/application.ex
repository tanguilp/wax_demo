defmodule WaxDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Phoenix.PubSub, name: WaxDemo.PubSub},
      # Start the endpoint when the application starts
      WaxDemoWeb.Endpoint
      # Starts a worker by calling: WaxDemo.Worker.start_link(arg)
      # {WaxDemo.Worker, arg},
    ]

    :ets.new(:wax_session, [:named_table, :public, read_concurrency: true])

    WaxDemo.User.init()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WaxDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WaxDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
