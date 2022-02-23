# frozen_string_literal: true

# Author: Hundter Biede (hbiede.com)
# Version: 1.0
# License: MIT

require 'csv'

# Parse vote records
class VoteParser
  # Determines if sufficient arguments were given to the program
  #   else, exits
  def self.vote_arg_count_validator(args)
    # print help if no arguments are given or help is requested
    return unless args.empty? || args.include?('--help')

    error_message = 'Usage: ruby %s [VoteInputFileName]'
    warn format(error_message, $PROGRAM_NAME)
    raise ArgumentError unless args.include?('--help')

    exit 0
  end

  # Read the contents of the given CSV file
  #
  # @param file_name [String] The name of the file
  # @return [Array<Array<String>>]the contents of the given CSV file
  def self.read_votes(file_name)
    begin
      # @type [Array<Array<String>>]
      csv = CSV.read(file_name)
    rescue Errno::ENOENT
      warn format('Sorry, the file %<File>s does not exist', File: file_name)
      exit 1
    end
    csv.delete_if { |line| line.join('') =~ /^\s*$/ } # delete blank lines
    csv
  end

  # Convert a list of rank choices to a ranked list of candidates
  #
  # @param rank_order [Array<String>] The list of rank options as listed in the CSV file (e.g., ["", "", "1", "2"])
  # @param candidate_list [Array<String>] The list of candidates in the same order as the rank_order array
  # @return [Array<String>] The list of candidates in rank order from most to least preferred
  def self.to_vote_rank(rank_order, candidate_list)
    rank_order
      .map(&:to_i)
      .zip(candidate_list)
      .filter { |rank, _| rank.positive? }
      .sort_by { |rank, _| rank }
      .map { |_, candidate| candidate }
  end

  # Trims the vote records so only voters with remaining preferences are left
  #
  # @param vote_records [Array<Array<String>>] Remaining vote records
  # @return [Array<Array<String>>] vote_records After trimming
  def self.trim_empty_voters(vote_records)
    vote_records.filter { |ranks| ranks.length.positive? }
  end

  # Remove the lowest vote earning candidate
  #
  # @param vote_records [Array<Array<String>>] Current vote records
  # @param candidate [String,NilClass] The candidate to remove
  # @return [Array<Array<String>>] vote_records After trimming candidate
  def self.remove_candidate(vote_records, candidate)
    return vote_records if candidate.nil?

    # @type [Array<Array<String>>]
    filtered = vote_records.map { |vote| vote.reject { |c| candidate == c } }
    trim_empty_voters(filtered)
  end

  # Gets a vote count per candidate. Small decimals are added to account
  # for ties in run-offs
  #
  # @param [Array<Array<String>>] vote_records Current vote records
  # @return [Hash{String=>Integer,Float}] The vote count per candidate
  def self.get_vote_count(vote_records)
    # @type [Hash{String=>Integer,Float}]
    vote_count = Hash.new(0)
    vote_records.each do |vote|
      vote.each_with_index do |c, i|
        vote_count[c] += 10**-i
      end
    end
    vote_count
  end

  # Gets the name of the winner of the election for this round, if one exists
  #
  # @param counts [Hash{String=>Integer,Float}] The vote count per candidate
  # @return [String] The name of the winning candidate iff one exists
  # @return [NilClass] Nil if there is not a winning candidate
  def self.get_winner(counts)
    counts.keys.find { |count| counts[count] > (counts.values.sum / 2) }
  end

  # Gets the name of the candidate who received the lowest vote count
  # Ties are broken by number of seconds, thirds, and fourths
  #
  # @param counts [Hash{String=>Integer,Float}] The vote count per candidate
  # @param candidates [Array<String>] The list of candidates
  # @return [String] The lowest vote-earning candidate
  # @return [NilClass] If no candidates or no count are provided
  def self.get_eliminated_candidate(counts, candidates)
    return nil if counts.empty? || candidates.empty?

    candidates
      .map { |c| [c, counts.key?(c) ? counts[c] : -1] }
      .min(1) { |a, b| a[1] <=> b[1] }[0][0]
  end

  # Returns the pluralization for a given count
  # For the purposes of this function, the range [1,2) is treated as non-plural
  #
  # @param count [Integer,Float,NilClass]
  # @return [String] 's' or ''
  def self.get_plural(count)
    !count.nil? && count >= 1 && count < 2 ? '' : 's'
  end

  # Generates an round report string for the vote counts
  #
  # @param counts [Hash{String=>Integer,Float}] The vote count per candidate
  # @return [String] The report
  def self.get_count_report(counts, candidates)
    candidates
      .sort_by { |c| -1 * (counts[c].nil? ? 0 : counts[c]) }
      .map do |c|
        format('%<Name>s: %<Count>d vote%<Plural>s',
               { Name: c, Count: counts[c].nil? ? 0 : counts[c], Plural: get_plural(counts[c]) })
      end
      .join "\n"
  end

  # Generates an round report string
  #
  # @param counts [Hash{String=>Integer,Float}] The vote count per candidate
  # @param winner [String, NilClass] The winner, if one exists
  # @return [String] The report
  def self.election_report(counts, winner, candidates)
    format("%<Report>s\n-----\n%<Result>s",
           {
             Report: get_count_report(counts, candidates),
             Result: if winner.nil?
                       format("%s eliminated\n\n\n", get_eliminated_candidate(counts, candidates))
                     else
                       format('%s won!', winner)
                     end
           })
  end

  # Process a single round of vote counts
  #
  # @param vote_records [Array<Array<String>>] Vote records for the round
  # @param candidates [Array<String>] The list of current candidates
  # @return [Array<((String,NilClass), Array<Array<String>>, Array<String>)>]
  def self.process_round(vote_records, candidates)
    counts = get_vote_count(vote_records)
    winner = get_winner(counts)
    puts election_report(counts, winner, candidates)
    # Winner found
    return [winner, vote_records, candidates] unless winner.nil?

    # No winner, eliminate a candidate
    eliminated = get_eliminated_candidate(counts, candidates)
    if eliminated.nil?
      warn 'Invalid votes'
      exit 2
    end
    [nil, remove_candidate(vote_records, eliminated), candidates.reject { |c| c == eliminated }]
  end

  # Process the full election til a winner is found
  #
  # @param vote_records [Array<Array<String>>] Vote records for the round
  # @param candidates [Array<String>] The list of current candidates
  # @return [String] The winner
  def self.process_election_rounds(vote_records, candidates)
    winner = nil
    current_votes = vote_records
    current_candidates = candidates
    winner, current_votes, current_candidates = process_round(current_votes, current_candidates) while winner.nil?
    winner
  end

  def self.process_election(args)
    VoteParser.vote_arg_count_validator args
    votes = VoteParser.read_votes(args[0])
    # @type [Array<Array<String>>]
    vote_records = votes[1..votes.length].map { |vote| to_vote_rank(vote, votes[0]) }
    process_election_rounds(vote_records, votes[0])
  end
end

# :nocov:
VoteParser.process_election ARGV if __FILE__ == $PROGRAM_NAME
# :nocov:
