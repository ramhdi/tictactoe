defmodule TictactoeWeb.Router do
  use TictactoeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TictactoeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_player_id
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TictactoeWeb do
    pipe_through :browser

    live "/", LobbyLive
    live "/game/:id", GameLive
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:tictactoe, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TictactoeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  defp assign_player_id(conn, _) do
    if get_session(conn, :player_id) do
      conn
    else
      player_id = :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
      put_session(conn, :player_id, player_id)
    end
  end
end
