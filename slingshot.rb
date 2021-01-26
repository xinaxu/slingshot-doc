#!/usr/bin/ruby
require 'rest-client'
require 'json'
project = ARGV[0]
desc = File.read(ARGV[1]).lines.map{|line|line.split(',')}.to_h unless ARGV[1].nil?
deals = JSON.parse(RestClient.get("https://space-race-slingshot-phase2.s3-us-west-2.amazonaws.com/prod/deals_list_#{project}.json").body)["payload"]
files = JSON.parse(RestClient.post("https://slingshot.filecoin.io/api/graphql", {operationName: "getDeals", query: "query getDeals($properties: JSON) {getDeals(properties: $properties)}", variables: {properties: {project: project}}}).body)["data"]["getDeals"]
deals.each do |deal|
  deal["filename"] = files[deal["deal_id"]]["filename"]
end
puts "## To get started"
puts "First, set a max price that you can bear"
puts "```"
puts "export MAX_PRICE=1"
puts "```"
deals.group_by{|deal| deal["filename"]}.to_a.sort_by{|k,v|k}.each do |filename, deals|
  puts "## #{filename}"
  puts "### #{desc[filename]}" if !desc.nil? && desc.has_key?(filename)
  puts "```"
  deals.each do |deal|
    puts "lotus client retrieve --maxPrice $MAX_PRICE --miner #{deal["miner_id"]} #{deal["payload_cid"]}"
  end
  puts "```"
end
