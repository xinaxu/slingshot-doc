#!/usr/bin/ruby
require 'nokogiri'
require 'fileutils'

Dir['prelinger/*'].filter{|file|File.directory? file}.select do |dir|
  xml_file = File.join(dir, "#{dir.split('/')[-1]}_meta.xml")
  next unless File.exists? xml_file
  xml = Nokogiri::XML(File.read(xml_file))
  name = File.join('prelinger', xml.at_xpath('//title').content.gsub('/', '_'))
  puts "Renaming #{dir} to #{name}"
  FileUtils.mv(dir, name) if dir != name
end
