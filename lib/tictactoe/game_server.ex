defmodule Tictactoe.GameServer do
  use GenServer
  alias Tictactoe.Game

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def join_game(player_id) do
    GenServer.call(__MODULE__, {:join_game, player_id})
  end

  def make_move(game_id, player_id, position) do
    GenServer.call(__MODULE__, {:make_move, game_id, player_id, position})
  end

  def get_game(game_id) do
    GenServer.call(__MODULE__, {:get_game, game_id})
  end

  @impl true
  def init(_) do
    {:ok, %{games: %{}, waiting_game_id: nil}}
  end

  @impl true
  def handle_call({:join_game, player_id}, _from, state) do
    case state.waiting_game_id do
      nil ->
        # Create a new game
        game_id = generate_id()
        game = Game.new(game_id) |> Game.add_player(player_id)

        new_state = %{
          state
          | games: Map.put(state.games, game_id, game),
            waiting_game_id: game_id
        }

        {:reply, {:ok, game}, new_state}

      waiting_game_id ->
        # Join the waiting game
        game = state.games[waiting_game_id] |> Game.add_player(player_id)

        # Update state
        new_state = %{
          state
          | games: Map.put(state.games, waiting_game_id, game),
            waiting_game_id:
              if(game.status == Game.status_playing(), do: nil, else: waiting_game_id)
        }

        # Broadcast game update with a safer approach
        :ok =
          Phoenix.PubSub.broadcast(
            Tictactoe.PubSub,
            "game:#{waiting_game_id}",
            {:game_updated, game}
          )

        {:reply, {:ok, game}, new_state}
    end
  end

  @impl true
  def handle_call({:make_move, game_id, player_id, position}, _from, state) do
    case Map.fetch(state.games, game_id) do
      {:ok, game} ->
        updated_game = Game.make_move(game, player_id, position)
        new_state = %{state | games: Map.put(state.games, game_id, updated_game)}

        # Broadcast game update with a safer approach
        :ok =
          Phoenix.PubSub.broadcast(
            Tictactoe.PubSub,
            "game:#{game_id}",
            {:game_updated, updated_game}
          )

        {:reply, {:ok, updated_game}, new_state}

      :error ->
        {:reply, {:error, :game_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_game, game_id}, _from, state) do
    case Map.fetch(state.games, game_id) do
      {:ok, game} -> {:reply, {:ok, game}, state}
      :error -> {:reply, {:error, :game_not_found}, state}
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
  end
end
