defmodule Tictactoe.Game do
  defstruct [
    :id,
    :player_x,
    :player_o,
    :current_player,
    :board,
    :status,
    :winner
  ]

  def status_waiting, do: "waiting"
  def status_playing, do: "playing"
  def status_finished, do: "finished"

  def new(id) do
    %__MODULE__{
      id: id,
      player_x: nil,
      player_o: nil,
      current_player: :x,
      board: %{
        "0,0" => nil,
        "0,1" => nil,
        "0,2" => nil,
        "1,0" => nil,
        "1,1" => nil,
        "1,2" => nil,
        "2,0" => nil,
        "2,1" => nil,
        "2,2" => nil
      },
      status: status_waiting(),
      winner: nil
    }
  end

  def add_player(game, player_id) do
    cond do
      game.player_x == nil ->
        %{
          game
          | player_x: player_id,
            status: if(game.player_o, do: status_playing(), else: status_waiting())
        }

      game.player_o == nil and game.player_x != player_id ->
        %{game | player_o: player_id, status: status_playing()}

      true ->
        game
    end
  end

  def make_move(game, player_id, position) do
    if can_move?(game, player_id, position) do
      game = put_in(game.board[position], game.current_player)

      case check_winner(game) do
        nil ->
          next_player = if game.current_player == :x, do: :o, else: :x
          %{game | current_player: next_player}

        winner ->
          %{game | status: status_finished(), winner: winner}
      end
    else
      game
    end
  end

  defp can_move?(game, player_id, position) do
    game.status == status_playing() and
      ((game.current_player == :x and game.player_x == player_id) or
         (game.current_player == :o and game.player_o == player_id)) and
      game.board[position] == nil
  end

  defp check_winner(game) do
    winning_combinations = [
      # Rows
      [game.board["0,0"], game.board["0,1"], game.board["0,2"]],
      [game.board["1,0"], game.board["1,1"], game.board["1,2"]],
      [game.board["2,0"], game.board["2,1"], game.board["2,2"]],
      # Columns
      [game.board["0,0"], game.board["1,0"], game.board["2,0"]],
      [game.board["0,1"], game.board["1,1"], game.board["2,1"]],
      [game.board["0,2"], game.board["1,2"], game.board["2,2"]],
      # Diagonals
      [game.board["0,0"], game.board["1,1"], game.board["2,2"]],
      [game.board["0,2"], game.board["1,1"], game.board["2,0"]]
    ]

    winning_line =
      Enum.find(winning_combinations, fn [a, b, c] -> a != nil and a == b and b == c end)

    cond do
      # We found a winning line
      winning_line != nil ->
        # Return the first element (they're all the same)
        List.first(winning_line)

      # No winner but all cells filled - it's a draw
      Enum.all?(game.board, fn {_k, v} -> v != nil end) ->
        :draw

      # Game still in progress
      true ->
        nil
    end
  end
end
