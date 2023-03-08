#!/bin/bash
#######################################################
# Script to interface with number_guess PSQL database #
# Created By: Jack Loomis                             #
# Creation Date: 3/8/2023                             #
#######################################################
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "\n~~~ Number Guessing Game ~~~\n"
echo -e "\nEnter your username:\n"

# get username variable to lookup/add to database
read USERNAME_ENTERED

# lookup username in database
USERNAME=$($PSQL "SELECT username FROM users WHERE username = '$USERNAME_ENTERED'")

# if username doesn't exist
if [[ -z $USERNAME ]]
then
  # add user to the database
  INSERT_USERNAME=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME_ENTERED')")
  echo "Welcome, $USERNAME_ENTERED! It looks like this is your first time here."
else
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username = '$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME'")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate random number for the answer
declare -i MAX_NUMBER=1000 # change this to change the difficulty (range of numbers smaller = easier, bigger = harder)
declare -i MIN_NUMBER=1
declare -i SECRET_NUMBER=$(($MIN_NUMBER + $RANDOM % $MAX_NUMBER))

echo -e "\nGuess the secret number between 1 and 1000:\n"
read PLAYER_GUESS

PLAYER_GUESS_COUNT=1
while [[ $PLAYER_GUESS != $SECRET_NUMBER ]]
do
  if ! [[ $PLAYER_GUESS =~ ^[0-9]+$ ]]
  then
    echo -e "\nThat is not an integer, guess again: (Current guess count: $PLAYER_GUESS_COUNT)"
    let PLAYER_GUESS_COUNT+=1
    read PLAYER_GUESS
  elif [[ $PLAYER_GUESS -gt $SECRET_NUMBER ]]
  then
    echo -e "\nIt's lower than that, guess again: (Current guess count: $PLAYER_GUESS_COUNT)"
    let PLAYER_GUESS_COUNT+=1
    read PLAYER_GUESS
  elif [[ $PLAYER_GUESS -lt $SECRET_NUMBER ]]
  then
    echo -e "\nIt's higher than that, guess again: (Current guess count: $PLAYER_GUESS_COUNT)"
    let PLAYER_GUESS_COUNT+=1
    read PLAYER_GUESS
  fi
done

if [[ $PLAYER_GUESS -eq $SECRET_NUMBER ]]
then
  echo -e "\nYou guessed it in $PLAYER_GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
  declare -i NEW_GAMES_PLAYED=$GAMES_PLAYED+1
  # echo -e "\nDEBUG: Games played: $NEW_GAMES_PLAYED"
  UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED WHERE username = '$USERNAME_ENTERED'")
  # get best_game variable
  BEST_GAME_OLD=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME_ENTERED'")
  # echo -e "\nDEBUG: Previous PB: $BEST_GAME_OLD"
  # if number of guesses was lower than player's previous best
  if [[ $BEST_GAME_OLD -gt $PLAYER_GUESS_COUNT || $BEST_GAME_OLD -eq 0 ]]
  then
    # update best_game with that number
    BEST_GAME_UPDATE=$($PSQL "UPDATE users SET best_game = $PLAYER_GUESS_COUNT WHERE username = '$USERNAME_ENTERED'")
    BEST_GAME_NEW=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME_ENTERED'")
    # echo -e "\nDEBUG: New PB: $BEST_GAME_NEW"
  fi
fi