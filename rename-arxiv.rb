#!/usr/bin/ruby
require 'json'
require 'fileutils'

puts "Parsing json"
#map = {}
#File.open('metadata/arxiv-metadata-oai-snapshot.json').each do |line|
#  json = JSON.parse(line)
#  map[json['id']] = json['title']
#end
map = JSON.parse(File.read('cache.json'))
puts "Parsing json completed"
#File.write('cache.json', JSON.generate(map))

Dir['pdf/**/*'].each do |name|
  next if File.directory? name
  paths = name.split('/')
  basename = File.basename(name, '.*')
  dirname = File.dirname(name)
  extname = File.extname(name)
  n = basename.index(/[0-9]/)
  if !n.nil? && n > 0
    basename = basename[0...n] + '/' + basename[n..-1]
  end
  if map.has_key? basename
    new_name = File.join(dirname, "#{map[basename].gsub('/', '_').gsub(/[^0-9a-zA-Z"',. +?@|:;%&*^!{}=_\-()\[\]\/]/, "")[0..200]}#{extname}")
    #puts "Renaming #{name} to #{new_name}"
  begin
    FileUtils.mv(name, new_name)
  rescue
    puts new_name
    exit
  end
  end
end
