defmodule TictactoeWeb.LobbyLive do
  use TictactoeWeb, :live_view
  alias Tictactoe.GameServer

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, player_id: session["player_id"])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto p-6 bg-white rounded-lg shadow-md">
      <h1 class="text-3xl font-bold mb-6 text-center">Tic-tac-toe</h1>
      
      <div class="mb-8 text-center">
        <p class="text-lg mb-4">Ready to play?</p>
        
        <button
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded-lg text-lg"
          phx-click="join_game"
        >
          Find a Game
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("join_game", _params, socket) do
    case GameServer.join_game(socket.assigns.player_id) do
      {:ok, game} ->
        {:noreply, push_navigate(socket, to: ~p"/game/#{game.id}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to join game: #{reason}")}
    end
  end
end
