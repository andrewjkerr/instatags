require 'asciiart'
require 'figaro'
require 'httparty'

def figaro_init
  Figaro.application = Figaro::Application.new(environment: 'production', path: 'config/application.yml')
  Figaro.load
  Figaro.require_keys('INSTAGRAM_CLIENT_ID')
end

def process_args
  if ARGV.size != 2
    puts "Incorrect usage!"
    puts "Please run the script followed by a tag and how many images you'd like to display"
    puts "For example, to display 10 corgi images, use `ruby fetch_imgs.rb corgi 10`"
    exit
  end

  tag = ARGV[0]
  max_image_count = ARGV[1].to_i
  [tag, max_image_count]
end

def fetch_images(tag, max_image_count)
  # Initial URL
  url = "https://api.instagram.com/v1/tags/#{tag}/media/recent?client_id=#{ENV['INSTAGRAM_CLIENT_ID']}"
  image_count = 0

  # We run out of images if we don't get a next_url returned
  until url.nil?
    instagram_response = HTTParty.get(url)
    url, data = process_response(instagram_response)
    image_count = process_images(data, image_count, max_image_count)

    # Check if we've reached out image count!
    return puts "Image count reached! :)" if image_count >= max_image_count
  end

  puts "Ran out of images to display. :("
end

# Grab the next_url and the data from the response
def process_response(response)
  instagram_hash = JSON.parse(response.body)
  next_url = instagram_hash.dig('pagination', 'next_url')
  data = instagram_hash.dig('data')
  [next_url, data]
end

# Process the image array
def process_images(data, image_count, max_image_count)
  data.each do |image|
    return image_count if image_count >= max_image_count
    print_image(image)
    image_count += 1
  end
  image_count
end

# Print the ASCII art of the image, the username/caption, and the url
def print_image(image)
  # Fuck yeah ASCII art
  image_url = image['images']['standard_resolution']['url']
  a = AsciiArt.new(image_url)
  puts a.to_ascii_art(color: true, width: 75)

  # Let's give the user some credit :)
  username = image['caption']['from']['username']
  caption = image['caption']['text']
  instagram_url = image['link']
  puts "#{username}: #{caption}"
  puts "Source: #{instagram_url}"
end

# Main script!
figaro_init
tag, max_image_count = process_args
fetch_images(tag, max_image_count)
