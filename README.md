[![Test and Lint](https://github.com/hbiede/Ranked-Choice-Voting/actions/workflows/test.yaml/badge.svg)](https://github.com/hbiede/Ranked-Choice-Voting/actions/workflows/test.yaml)
[![codecov](https://codecov.io/gh/hbiede/Ranked-Choice-Voting/graph/badge.svg)](https://codecov.io/gh/hbiede/Ranked-Choice-Voting)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

# Rank-Choice-Voting
A Ruby tool to calculate the winner in a ranked choice voting election

## Requirements
 - [Ruby](https://www.ruby-lang.org/en/)
 - [GNU Make](https://www.gnu.org/software/make/) (optional but recommended)

## Usage

### Installation
```
git clone https://github.com/hbiede/Ranked-Choice-Voting.git
cd Voter-Tokens
```

### Setup

The CSV used as input is expected to have all columns with a series of columns
representing the candidates. The header row should contain candidate names and the
all subsequent rows should contain the preference ranking for each candidate by a single
voter (rank 1 is most preferred and preference decreases as rank increases). 
**Note**: The candidates will be sorted in ascending order for each vote record, so a vote record
where Candidate A gets rank 1 and Candidate B gets rank 2 is equivalent to a vote record where
Candidate A gets rank 4 and Candidate B gets rank 5.

### Parse Ballots
Download the CSV of your ballots to data/votes.csv and then run the following command:
```
ruby vote_parser.rb data/votes.csv
```

#### Parse Ballots from Google Sheets
If your ballots are stored on the first sheet of a Google Sheet in range B1:G, you can
download and parse votes all in one command:
```
make URL=https://docs.google.com/spreadsheets/d/DOCUMENT_ID/export?exportFormat=csv&range=B1:G
```
**Note: you must change DOCUMENT_ID to the alphanumeric code in the link to your Google
Sheet. The Sheet *must* be set as viewable by anyone with the link.**