default: countVotes

# Download and extract first and last columns
# Example URL = https://docs.google.com/spreadsheets/d/DOCUMENT_ID/export?exportFormat=csv&range=B1:G
countVotes:
	@curl -s '${URL}' > data/votes.csv
	@ruby vote_parser.rb data/votes.csv
