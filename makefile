default: countVotes

# Download and extract first and last columns
# @data/votes.csv | perl -pe 's/^[\d\/\\\-\:\s\w]+,//g and s/,[\d\/\\\-\:\s\w]+$$/\n/g' > data/votes.csv
# Example URL = https://docs.google.com/spreadsheets/d/DOCUMENT_ID/export?exportFormat=csv&range=B1:G
countVotes:
	@curl -s '${URL}' > data/votes.csv
	@ruby vote_parser.rb data/votes.csv
