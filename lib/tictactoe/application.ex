defmodule Tictactoe.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TictactoeWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:tictactoe, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Tictactoe.PubSub},
      {Finch, name: Tictactoe.Finch},
      # Add the game server to the supervision tree
      {Tictactoe.GameServer, []},
      TictactoeWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Tictactoe.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TictactoeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
