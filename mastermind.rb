# frozen_string_literal: true

# This module acts as a namespace for the mastermind game
module Mastermind
  CODE_PEGS = {
    'red' => "\e[41m   1   \e[0m",
    'green' => "\e[42m   2   \e[0m",
    'yellow' => "\e[43m   3   \e[0m",
    'blue' => "\e[44m   4   \e[0m",
    'magenta' => "\e[45m   5   \e[0m",
    'cyan' => "\e[46m   6   \e[0m",
    'white' => "\e[47m   7   \e[0m"
  }.freeze

  KEY_PEGS = {
    'b' => "\e[34m\u2b24\s\e[0m",
    'w' => "\e[37m\u2b24\s\e[0m"
  }.freeze

  INSTRUCTION = <<~HEREDOC
    Mastermind or Master Mind is a code-breaking game for two players.\n
    \e[4mGameplay and rules\e[0m
      - Decide in advance how many games to play, which must be an even number.
      - There are two roles available for the players: Codemaker and Codebreaker.
      - The Codemaker picks four colors as a code from following color list:\n
          #{CODE_PEGS.values.join(' | ')}\n
      - The Codebreaker tries to guess the pattern, in both order and color, within twelve turns.
      - Once done, the Codemaker provides feedback by using #{KEY_PEGS['b']} and #{KEY_PEGS['w']} colors.
        - #{KEY_PEGS['b']} color is for each color code from the guess which is correct in both color and position.
        - #{KEY_PEGS['w']} color indicates the existence of a correct color code peg placed in the wrong position.
      - Once feedback is provided, another guess is made; guesses and feedback continue to alternate until either the Codebreaker guesses correctly, or all the turns are used.
      - Players can only earn points when playing as the Codemaker.
      - The Codemaker gets one point for each guess the Codebreaker makes.
      - An extra point is earned by the Codemaker if the Codebreaker is unable to guess the exact pattern within the given number of turns.
  HEREDOC

  def self.init
    puts 'Welcome to Mastermind Game'
    puts INSTRUCTION
    game = Game.new
    game.play
  end

  # This class represents a human player
  class Human
    attr_accessor :points

    def initialize
      @points = 0
    end

    # see(#code_input)
    def code
      print "Choose 4 colors from below as the code:\n\s\s#{CODE_PEGS.values.join(' | ')}\n\s\sCode:"
      code_input
    end

    # (see #code_input)
    def guess
      print 'Guess the code. '
      code_input
    end

    # Returns the 4-color code in an array
    #
    # @return [Array] the 4-color code (eg. %w[red cyan blue blue])
    def code_input
      loop do
        user_input = gets.chomp
        return convert_to_code(user_input) if validate_code_input(user_input)

        print 'Must be 4 digits between 1111 and 7777. '
      end
    end

    # Validates the user's input for code
    #
    # @param input [String] user's input for code
    # @return [Boolean]
    def validate_code_input(input)
      input.match?(/\b\d{4}\b/) && input.to_i.between?(1111, 7777)
    end

    # Convert user's input to the color-code array
    #
    # @param user_input [String] user's input
    # @return [Array] color-code array (eg. %w[red cyan blue blue])
    def convert_to_code(user_input)
      user_input.split('').map { |cha| CODE_PEGS.keys[cha.to_i - 1] }
    end
  end

  #   # This class represents a computer player
  class Computer
    attr_accessor :points

    def initialize
      @points = 0
    end

    # Generates random 4-color code in an array
    #
    # @return [Array] the 4-color code (eg. %w[red cyan blue blue])
    def code
      random_code = []
      4.times { random_code.push(CODE_PEGS.keys.sample) }
      random_code
    end

    # (see code)
    def guess
      random_code = []
      4.times { random_code.push(CODE_PEGS.keys.sample) }
      random_code
    end
  end

  # This class represents a mastermind game
  class Game
    def play
      total_rounds = rounds
      round = 1
      assign_roles(role)
      repeat_until_no_round_left(round, total_rounds)
    end

    private

    # Repeat until current round reaches provided total rounds
    #
    # @param round [Number] current round
    # @param total_rounds [Number] total rounds to play
    def repeat_until_no_round_left(round, total_rounds)
      while round <= total_rounds
        puts "Round #{round} of #{total_rounds}"
        switch_roles unless round == 1
        turns = 12
        code = @codemaker.code
        repeat_until_no_turn_left_or_solved(turns, code)
        puts "Codemaker's points: #{@codemaker.points} | Codebreaker's points: #{@codebreaker.points}"
        round += 1
      end
    end

    # Repeats guess and feedback until turns become 0 or codebreake solves the code
    #
    # @param turns [Number] turns left to guess
    # @param code [Array] the codemaker's 4-color code
    def repeat_until_no_turn_left_or_solved(turns, code)
      loop do
        guess = @codebreaker.guess
        feedback = feedback(guess, code)
        puts decoding_board(guess, feedback)
        turns -= 1
        @codemaker.points += 1
        puts "Codemaker's points: #{@codemaker.points}"
        return @codemaker.points += 1 if turns.zero?
        return if guess.eql?(code)
      end
    end

    # Validates the user's input for role and returns either 'codemaker' or 'codebreaker'
    #
    # @return [String] either 'codemaker' or 'codebreaker', based on user's input
    def role
      roles = %w[codemaker codebreaker]
      print "Choose a role.\n\s\s1. #{roles[0].capitalize}\n\s\s2. #{roles[1].capitalize}\nAns: "
      loop do
        user_input = gets.chomp.to_i
        return roles[user_input - 1] if user_input.between?(1, 2)

        print 'Must be 1 or 2. '
      end
    end

    # Assigns roles for each player
    #
    # @param user_role [String] role user picked
    def assign_roles(user_role)
      @codemaker = user_role == 'codemaker' ? Human.new : Computer.new
      @codebreaker = user_role == 'codebreaker' ? Human.new : Computer.new
    end

    # Validates the user's input for total game rounds and returns it
    #
    # @return [Number] total numbers of game round
    def rounds
      print 'How many games do you want to play? '
      loop do
        user_input = gets.chomp
        return user_input.to_i if user_input.match?(/\d/) && user_input.to_i.even?

        print 'Must be an even number. '
      end
    end

    # Generates feedback array
    #
    # @param guess [Array] the array for guessed code
    # @param code [Array] the array for real code
    # @ return [Array] the array that shows the feedback
    def feedback(guess, code)
      feedback = []
      guess.each_with_index do |color, index|
        if code[index] == color
          feedback << KEY_PEGS.keys[0]
        elsif code.include?(color)
          feedback << KEY_PEGS.keys[1]
        end
      end
      feedback
    end

    # Generates decoding board in string from provided guess and feedback
    #
    # @param guess [Array] 4-color code array
    # @param feedback [Array] feedback array
    # @return [String] decoding board in multi-line string
    def decoding_board(guess, feedback)
      decoding_board = []
      decoding_board << guess + feedback
      board_text = decoding_board.map { |row| row.map { |color| CODE_PEGS[color] || KEY_PEGS[color] }.join(' ') }.join("\n\n")
      <<~HEREDOC
        Decoding board: #{board_text}
      HEREDOC
    end

    def switch_roles
      temp = @codemaker
      @codemaker = @codebreaker
      @codebreaker = temp
    end
  end
end

Mastermind.init
