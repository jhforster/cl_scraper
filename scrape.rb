require 'mechanize'
require 'pry-byebug'
require 'csv'

# Instantiate a new web scraper with Mechanize
scraper = Mechanize.new

# Rate limit the requests to avoid trouble
scraper.history_added = Proc.new { sleep 0.9 }

# Set urls as variables for future flexibility
BASE_URL = 'http://boston.craigslist.org'
ADDRESS = 'http://boston.craigslist.org/search/ggg'

# Arrays to store results
results =[]
name_dupe = []

# First row in csv will be column names
results << ['Name', 'URL']

# Built as a loop so this could work on a # of search pages
# Loads the results into search_page
scraper.get(ADDRESS) do |search_page|

  # Mechanize enters search terms into the form field
  form = search_page.form_with(:id => 'searchform') do |search|
    search['query'] = 'research'
  end
  # Submits form and stores results
  results_page = form.submit

  # Creates an array for all the elements with class result-info (only p-tags)
  raw_results = results_page.bases_with(class: 'result-info')

  # Parse each p tag for name and url
  raw_results.each do |result|
    # Finds the first a tag within the p tag
    link = result.links[0]
    # Extracts the display text from the a tag
    name = link.text
    # Concatenates to provide the full url address
    url = BASE_URL + link.uri

    # Click the link and go to a new page
    new_page = link.click

    # Checks to make sure the name has not already been stored to remove duplicate listings
    if !(name_dupe.include? name)
      name_dupe << name
      results << [name, url]
    end

    # Add logic to get(URL) and scrape for the email as part of this loop
  end

  # Output results array to a CSV file
  CSV.open("filename.csv", "w+") do |csv_file|
    results.each do |row|
      csv_file << row
    end
  end

end
