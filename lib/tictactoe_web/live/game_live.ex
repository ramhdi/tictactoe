defmodule TictactoeWeb.GameLive do
  use TictactoeWeb, :live_view
  alias Tictactoe.{Game, GameServer}

  @impl true
  def mount(%{"id" => game_id}, session, socket) do
    player_id = session["player_id"]

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Tictactoe.PubSub, "game:#{game_id}")
    end

    case GameServer.get_game(game_id) do
      {:ok, game} ->
        player_mark =
          cond do
            game.player_x == player_id -> :x
            game.player_o == player_id -> :o
            true -> nil
          end

        {:ok,
         assign(socket,
           game_id: game_id,
           player_id: player_id,
           player_mark: player_mark,
           game: game
         )}

      {:error, _reason} ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto p-6 bg-white rounded-lg shadow-md">
      <h1 class="text-2xl font-bold mb-4 text-center">Tic-tac-toe Game</h1>
      
    <!-- Game status info -->
      <div class="mb-6 text-center">
        <%= cond do %>
          <% @game.status == Game.status_waiting() -> %>
            <p class="text-yellow-600 text-lg mb-2">Waiting for another player to join...</p>
          <% @game.status == Game.status_playing() -> %>
            <p class="text-lg mb-2">
              You are playing as
              <span class="font-bold">{String.upcase(to_string(@player_mark))}</span>
            </p>
            
            <p class={
              if @game.current_player == @player_mark, do: "text-green-600", else: "text-gray-600"
            }>
              <%= if @game.current_player == @player_mark do %>
                Your turn
              <% else %>
                Opponent's turn
              <% end %>
            </p>
          <% @game.status == Game.status_finished() -> %>
            <div class="bg-blue-100 p-4 rounded-lg mb-4">
              <p class="text-xl font-bold">
                <%= cond do %>
                  <% @game.winner == :draw -> %>
                    Game ended in a draw!
                  <% @game.winner == @player_mark -> %>
                    You won the game!
                  <% true -> %>
                    You lost the game.
                <% end %>
              </p>
            </div>
        <% end %>
      </div>
      
    <!-- Game board -->
      <div class="grid grid-cols-3 gap-2 max-w-xs mx-auto mb-6">
        <%= for row <- 0..2, col <- 0..2 do %>
          <% position = "#{row},#{col}" %>
          <button
            class="h-20 w-20 bg-gray-200 hover:bg-gray-300 flex items-center justify-center text-3xl font-bold rounded"
            phx-click="make_move"
            phx-value-position={position}
            disabled={
              @game.status != Game.status_playing() or @game.current_player != @player_mark or
                @game.board[position] != nil
            }
          >
            <%= case @game.board[position] do %>
              <% :x -> %>
                X
              <% :o -> %>
                O
              <% _ -> %>
                &nbsp;
            <% end %>
          </button>
        <% end %>
      </div>
      
    <!-- Back to lobby button -->
      <div class="text-center mt-6">
        <a href="/" class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">
          Back to Lobby
        </a>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("make_move", %{"position" => position}, socket) do
    GameServer.make_move(socket.assigns.game_id, socket.assigns.player_id, position)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_updated, game}, socket) do
    # Safely update the game state
    try do
      {:noreply, assign(socket, game: game)}
    rescue
      error ->
        IO.inspect(error, label: "Error handling game update")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(message, socket) do
    # Handle any other unexpected messages
    IO.inspect(message, label: "Unexpected message")
    {:noreply, socket}
  end
end
