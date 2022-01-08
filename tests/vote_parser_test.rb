# Author: Hundter Biede (hbiede.com)
# Version: 1.0
# License: MIT
require_relative '../vote_parser'
require_relative './helper'

#noinspection RubyResolve
class TestVoteParser < Test::Unit::TestCase
  def test_vote_arg_count_validator
    assert_nothing_raised do
      VoteParser.vote_arg_count_validator ["data/votes.csv"]
    end

    assert_raises ArgumentError do
      VoteParser.vote_arg_count_validator []
    end

    assert_raises SystemExit do
      VoteParser.vote_arg_count_validator %w[--help]
    end
  end

  def test_read_tokens
    file = 'test_read_tokens.csv'
    CSV.open(file, 'w') do |f|
      f << ["Candidate A", "Candidate B", "Candidate C", "Candidate D"]
      f << %w[1 2 3 4]
      f << %w[3 4 1 2]
      f << %w[]
      f << ["", "", "1", "2"]
      f << ["1", "", "", ""]
      f << %w[]
    end

    assert_equal([
                   ["Candidate A", "Candidate B", "Candidate C", "Candidate D"],
                   %w[1 2 3 4],
                   %w[3 4 1 2],
                   ["", "", "1", "2"],
                   ["1", "", "", ""],
                 ], VoteParser.read_votes(file))

    File.delete file

    begin
      VoteParser.read_votes('fake_csv_file.csv')
    rescue SystemExit
      assert_true true
    else
      assert_true false
    end
  end

  def test_to_vote_rank
    assert_equal(%w[C B A], VoteParser.to_vote_rank(["3", "2", "1", ""], %w[A B C D]))
    assert_equal(%w[A B C D], VoteParser.to_vote_rank(%w[1 2 3 4], %w[A B C D]))
    assert_equal(%w[A], VoteParser.to_vote_rank(["1", "", "", ""], %w[A B C D]))
    assert_equal(%w[A D], VoteParser.to_vote_rank(["1", "", "", "2"], %w[A B C D]))
    assert_equal(%w[A D], VoteParser.to_vote_rank(["3", "", "", "4"], %w[A B C D]))
    assert_equal(%w[A D], VoteParser.to_vote_rank(["3", "", "", "4"], %w[A B C D]))
    assert_equal(%w[A B D], VoteParser.to_vote_rank(["1", "2", "", "4"], %w[A B C D]))
    assert_equal(%w[C D A B], VoteParser.to_vote_rank(%w[3 4 1 2], %w[A B C D]))
  end

  def test_trim_empty_voters
    assert_equal([], VoteParser.trim_empty_voters([[], [], [], []]))
    assert_equal([%w[1 2 3]], VoteParser.trim_empty_voters([[], [], %w[1 2 3], []]))
    assert_equal([%w[1 2 3], %w[A B C]], VoteParser.trim_empty_voters([[], [], %w[1 2 3], %w[A B C]]))
    assert_equal([%w[A], %w[A B C D], %w[A B C]], VoteParser.trim_empty_voters([[], %w[A], %w[A B C D], %w[A B C], []]))
  end

  def test_remove_candidate
    assert_equal([%w[B], %w[C B], %w[D B C], %w[B C]], VoteParser.remove_candidate([%w[B], %w[C B A], %w[A], %w[D B C], %w[A B C]], "A"))
    assert_equal([%w[B], %w[C B A], %w[A], %w[D B C], %w[A B C]], VoteParser.remove_candidate([%w[B], %w[C B A], %w[A], %w[D B C], %w[A B C]], nil))
    assert_equal([%w[C A], %w[A], %w[D C], %w[A C]], VoteParser.remove_candidate([%w[B], %w[C B A], %w[A], %w[D B C], %w[A B C]], "B"))
    assert_equal([%w[D]],
                 VoteParser.remove_candidate(
                   VoteParser.remove_candidate(
                     VoteParser.remove_candidate(
                       [%w[B], %w[C B A], %w[A], %w[D B C], %w[A B C]],
                       "A"),
                     "B"),
                   "C")
    )
    assert_equal([], VoteParser.remove_candidate([%w[A]], "A"))
  end

  def test_get_vote_count
    assert_equal({ "A" => 1 }, VoteParser.get_vote_count([%w[A]]))
    assert_equal({ "A" => 5 }, VoteParser.get_vote_count([%w[A], %w[A B C], %w[A D B], %w[A C B D], %w[A]]))
    assert_equal({ "A" => 3, "B" => 1, "C" => 2, "D" => 1 }, VoteParser.get_vote_count([%w[A], %w[B A C], %w[A D B], %w[C D], %w[A], %w[D], %w[C D B]]))
  end

  def test_get_winner
    assert_equal(nil, VoteParser.get_winner({ "A" => 3, "B" => 1, "C" => 2, "D" => 1 }))
    assert_equal("A", VoteParser.get_winner({ "A" => 7, "B" => 1, "C" => 2, "D" => 1 }))
    assert_equal(nil, VoteParser.get_winner({}))
    assert_equal(nil, VoteParser.get_winner({ "A" => 1, "B" => 1, "C" => 1, "D" => 1 }))
    assert_equal(nil, VoteParser.get_winner({ "A" => 2, "C" => 1, "D" => 1 }))
    assert_equal(nil, VoteParser.get_winner({ "A" => 2, "C" => 2 }))
  end

  def test_get_eliminated_candidate
    assert_equal("B", VoteParser.get_eliminated_candidate({ "A" => 3, "B" => 1, "C" => 2, "D" => 1 }, %w[A B C D]))
    assert_equal("D", VoteParser.get_eliminated_candidate({ "A" => 3, "B" => 1, "C" => 2 }, %w[A B C D]))
    assert_equal("B", VoteParser.get_eliminated_candidate({ "A" => 3, "B" => 1, "C" => 2 }, %w[A B C]))
    assert_equal("B", VoteParser.get_eliminated_candidate({ "C" => 1 }, %w[A B C D]))
    assert_equal("C", VoteParser.get_eliminated_candidate({ "A" => 3, "C" => 2 }, %w[A C]))
    assert_equal(nil, VoteParser.get_eliminated_candidate({}, %w[A C]))
    assert_equal(nil, VoteParser.get_eliminated_candidate({ "A" => 3, "C" => 2 }, []))
  end

  def test_election_report
    assert_equal(
      "A: 5 votes\nC: 1 vote\nA won!\n\n",
      VoteParser.election_report({ "A" => 5, "C" => 1 }, "A", %w[A C])
    )
    assert_equal(
      "A: 5 votes\nB: 3 votes\nC: 1 vote\nA won!\n\n",
      VoteParser.election_report({ "A" => 5, "B" => 3, "C" => 1 }, "A", %w[A B C])
    )
    assert_equal(
      "A: 5 votes\nB: 3 votes\nC: 1 vote\nD: 0 votes\nA won!\n\n",
      VoteParser.election_report({ "A" => 5, "B" => 3, "C" => 1 }, "A", %w[A B C D])
    )
    assert_equal(
      "A: 4 votes\nB: 3 votes\nC: 1 vote\nD: 0 votes\nD eliminated\n\n",
      VoteParser.election_report({ "A" => 4, "B" => 3, "C" => 1 }, nil, %w[A B C D])
    )
    assert_equal(
      "B: 1 vote\nA: 0 votes\nA eliminated\n\n",
      VoteParser.election_report({ "B" => 1 }, nil, %w[A B])
    )
  end

  def test_process_round
    votes = [%w[A]]
    candidates = %w[A B C D]
    assert_equal(
      ["A", votes, candidates],
      VoteParser.process_round(votes, candidates)
    )

    votes = [%w[A B C D], %w[B], %w[A C], %w[A D]]
    candidates = %w[A B C D]
    assert_equal(
      ["A", votes, candidates],
      VoteParser.process_round(votes, candidates)
    )

    votes = [%w[A B C D], %w[B], %w[A C], %w[B D], %w[C D]]
    candidates = %w[A B C D]
    assert_equal(
      [nil, [%w[A B C], %w[B], %w[A C], %w[B], %w[C]], %w[A B C]],
      VoteParser.process_round(votes, candidates)
    )

    assert_raises SystemExit do
      VoteParser.process_round(votes, [])
    end
  end

  def test_process_election_rounds
    assert_equal(
      "A",
      VoteParser.process_election_rounds(
        [%w[A B C D], %w[A C], %w[B C A D], %w[B C], %w[C D A], %w[D A], %w[A D], %w[A B], %w[D C A], %w[A C B]],
        %w[A B C D]
      )
    )
  end

  def test_process_election
    file = 'test_process_election.csv'
    CSV.open(file, 'w') do |f|
      f << %w[A B C D]
      f << %w[1 2 3 4]
      f << ["1", "", "2"]
      f << %w[3 1 2 4]
      f << ["", "1", "2", ""]
      f << ["3", "", "1", "2"]
      f << ["2", "", "", "1"]
      f << ["1", "", "", "2"]
      f << ["1", "2", "", ""]
      f << ["3", "", "2", "1"]
      f << ["1", "3", "2", ""]
    end

    assert_equal(
      "A",
      VoteParser.process_election([file])
    )
    File.delete file
  end
end
