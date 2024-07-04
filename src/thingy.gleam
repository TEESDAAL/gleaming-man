import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/string_builder

pub type GameResult {
  Win
  Loss
}

pub fn main() {
  let word_to_guess = "noils" |> string.to_graphemes
  let guessed_letters = word_to_guess |> list.map(fn(_) { "_" })
  case game_loop(word_to_guess, guessed_letters, [], 10) {
    Win -> {
      io.println("The word was " <> word_to_guess |> join(""))
      io.println(
        "Congrats on guessing " <> word_to_guess |> list_to_string <> "!",
      )
    }
    Loss ->
      io.println(
        "You lost :(, the word was " <> word_to_guess |> list_to_string <> "!",
      )
  }
}

fn game_loop(
  word_to_guess: List(String),
  guessed_letters: List(String),
  prev_guesses: List(String),
  guesses_left: Int,
) -> GameResult {
  case guessed_letters |> none_match(fn(l) { l == "_" }) {
    _ if guesses_left == 0 -> Loss

    True -> Win

    False -> {
      io.println("You've guessed: " <> join(prev_guesses, ", "))
      io.println(
        "You have " <> guesses_left |> int.to_string <> " guesses left!!",
      )
      io.println(guessed_letters |> join(" "))

      let guess = get_user_guess(prev_guesses)

      let new_guessed_letters =
        reveal_letters(guessed_letters, word_to_guess, guess)

      game_loop(
        word_to_guess,
        new_guessed_letters,
        list.append(prev_guesses, [guess]),
        guesses_left - 1,
      )
    }
  }
}

fn get_user_guess(guessed_letters: List(String)) -> String {
  case
    erlang.get_line("Word to guess: ")
    |> result.map_error(fn(_) { panic as "Failed to read line" })
    |> result.map(fn(s) { string.drop_right(s, 1) })
    |> result.then(fn(s) {
      case string.length(s) {
        1 -> Ok(s)
        _ -> Error("Guess Must be 1 character")
      }
    })
    |> result.then(fn(s) {
      case list.contains(guessed_letters, s) {
        False -> Ok(s)
        _ -> Error(s <> " has already been guessed.")
      }
    })
  {
    Ok(val) -> val
    Error(e) -> {
      io.println(e)
      get_user_guess(guessed_letters)
    }
  }
}

fn list_to_string(list: List(String)) -> String {
  list
  |> list.fold(string_builder.new(), string_builder.append)
  |> string_builder.to_string
}

fn reveal_letters(
  guessed_letters: List(String),
  original_word: List(String),
  guess: String,
) -> List(String) {
  list.zip(guessed_letters, original_word)
  |> list.map(fn(guessed_original_pair) {
    case guessed_original_pair {
      #(_, original_letter) if guess == original_letter -> guess
      #(guessed_letter, _) -> guessed_letter
    }
  })
}

fn none_match(lst: List(t), predicate: fn(t) -> Bool) -> Bool {
  lst |> list.fold(True, fn(prev_match, t) { prev_match && !predicate(t) })
}

fn join(lst: List(String), seperator: String) {
  lst
  |> list.fold("", fn(sub_string, s) { sub_string <> s <> seperator })
  |> string.drop_right(string.length(seperator))
}
