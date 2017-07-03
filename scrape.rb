require 'mechanize'
require 'pry-byebug'
require 'csv'

# Instantiate a new web scraper with Mechanize
scraper = Mechanize.new

# Random number generator
prng = Random.new

# Rate limit the requests to avoid trouble
scraper.history_added = Proc.new { sleep 0.9 }

# Set urls as variables for future flexibility
BASE_URL = 'http://boston.craigslist.org'
ADDRESS = 'http://boston.craigslist.org/search/ggg'
USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36'

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

  # Creates an array for all the link elements with class result-title
  links = results_page.links_with(class: /result-title/)

  # Parse each link for name and url
  links.each do |link|
    # Extracts the display text from the a tag
    name = link.text

    # Full url of the link
    url = link.resolved_uri

    # Checks to make sure the name has not already been stored to remove duplicate listings
    if !(name_dupe.include? name)
      name_dupe << name

      reply_link = nil

      # Scrape the listing page
      scraper.get(url) do |listing_page|
        # listing_number = url.match(/\d+\.html\z/)[0].split('.')[0]
        # Click the "reply" button to trigger the dropdown
        reply_link = listing_page.link_with!(id: 'replylink')
        puts reply_link.resolved_uri
      end

      reply_email = nil

      # Scrape the contact info page
      scraper.get(reply_link.resolved_uri, [], url, {'User-Agent' => USER_AGENT}) do |contact_page|
        reply_email = contact_page.link_with!(class: 'mailapp').text
      end

      results << [name, url, reply_email]

      # Add random delay to rate limit + avoid looking too bot-like
      # sleep prng.rand(0.9..10.0)
    end
  end

  # Output results array to a CSV file
  CSV.open("filename.csv", "w+") do |csv_file|
    results.each do |row|
      csv_file << row
    end
  end

end
