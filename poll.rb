#!/usr/bin/env ruby
require 'feedjira'
require 'json'
require 'time'
require 'pocket-ruby'
require 'httparty'
require 'pry'

def add_to_pocket(consumer_key, access_token, url, title)
  client = Pocket::Client.new(consumer_key: consumer_key, access_token: access_token)
  client.add(url: url, title: title)
  puts "Added to Pocket: #{title}"
end

def check_feeds(feed_urls, consumer_key, access_token)
  known_links = load_known_links

  loop do
    feed_urls.each do |feed_url|
      resp = HTTParty.get(feed_url)
      if resp.code != 200
        puts "response code #{resp.code} for #{feed_url}"
        next
      end
      xml = resp.body

      feed = Feedjira.parse(xml)

      puts "#{feed_url}, #{feed.entries.count} entries"
      feed.entries.each do |entry|
        unless known_links.include?(entry.url)
          puts "- #{entry.title}"
          puts "  Published: #{entry.published}"
          puts "  Link: #{entry.url}\n"

          add_to_pocket(consumer_key, access_token, entry.url, entry.title)
          known_links << entry.url
        end
      end
    end

    save_known_links(known_links)

    # Adjust the sleep duration (in seconds) based on how frequently you want to check the feeds
    puts "sleeping"
    sleep(15 * 60) # Wait for 15 minutes
  end
end

def load_known_links
  Set.new(JSON.parse(File.read('known_links.json')))
end

def save_known_links(known_links)
  File.write('known_links.json', JSON.pretty_generate(known_links.to_a))
end

rss_feeds = File.read('links.lst').lines.grep(/^http/).map(&:chomp).uniq

check_feeds(rss_feeds, ARGV[1], ARGV[2])

