#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=postgres -t --no-align -c"

WIN() {
  NEW_GAMES_GUESSES=$1
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME';")
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users where username='$USERNAME';")
  if (( $NEW_GAMES_GUESSES < $BEST_GAME ))
  then
    UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game = $NEW_GAMES_GUESSES WHERE username = '$USERNAME';")
  fi
  UPDATE_GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played = $(($GAMES_PLAYED + 1)) WHERE username = '$USERNAME';")
}

GUESS() {
  NUMBER=$1
  NUM_GUESSES=$2
  if [[ -z $3 ]]
  then
    #we are in round 1
    echo "Guess the secret number between 1 and 1000:"
  elif [[ $3 = "lower" || $3 = "higher" ]]
  then
    #we are in another round where they missed
    echo "It's $3 than that, guess again:"
  elif [[ $3 = "error" ]]
  then
    #they didn't give an integer
    echo "That is not an integer, guess again:"
  fi
  read GUESS
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    #guess was invalid
    GUESS $NUMBER $(($NUM_GUESSES + 1)) "error"
  else
    if (( $GUESS == $NUMBER ))
    then
      WIN $(($NUM_GUESSES + 1))
      echo "You guessed it in $(($NUM_GUESSES + 1)) tries. The secret number was $NUMBER. Nice job!"
    else
      if (( $GUESS > $NUMBER ))
      then
        GUESS $NUMBER $(($NUM_GUESSES + 1)) "lower"
      else
        GUESS $NUMBER $(($NUM_GUESSES + 1)) "higher"
      fi 
    fi
  fi
}

PLAY_GAME() {
  echo "Enter your username:"
  read USERNAME
  USERNAME_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")
  if [[ $USERNAME_ID ]]
  then
    #pull user data
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username = '$USERNAME';")
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME';")
    #print personalised intro
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  else
    #insert the user into the database
    INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME');")
    #print general output
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  fi
  NUMBER=$((1 + $RANDOM % 1000))
  GUESS $NUMBER 0
}

PLAY_GAME