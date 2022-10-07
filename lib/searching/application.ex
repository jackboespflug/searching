defmodule Searching.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SearchingWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Searching.PubSub},
      # Start the Endpoint (http/https)
      SearchingWeb.Endpoint
      # Start a worker by calling: Searching.Worker.start_link(arg)
      # {Searching.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Searching.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SearchingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
