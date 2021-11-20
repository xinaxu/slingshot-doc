#!/usr/bin/ruby
require 'fileutils'
require 'pathname'
require 'slop'
require 'json'

opts = Slop::Options.new
opts.banner = 'Usage: ./spacecar.rb [options]'
opts.string '-i', '--input', 'Source directory for the dataset', required: true
opts.string '-t', '--temp', 'Temporary directory to process the dataset', required: true
opts.string '-o', '--output', 'Destination directory to store car files', required: true
opts.int '-s', '--sector', 'Maximum size of a single car file', default: 34359738368 # 32G
opts.int '-l', '--limit', 'Maximum size of a single file within the car archive', default: 17179869184 # 16G
opts.int '-x', '--split', 'Size of splitted file if an individual file is more than the maximum limit', default: 17179869184 # 16G
opts.on '-h', '--help', 'print help' do
  puts opts
  exit
end
parser = Slop::Parser.new(opts)
begin
  options = parser.parse(ARGV)
rescue
  puts opts
  exit
end

input = options[:input]
output = options[:output]
temp = options[:temp]
sector = options[:sector]
limit = options[:limit]
split = options[:split]
split = limit if split > limit

puts "== Processing the source folder"
paths = Pathname.glob(File.join(input, '**', '*'))
puts "Total number of paths: #{paths.length}"
paths.each do |path|
  if path.file? && path.size > limit
    puts "Splitting #{path} into chunks"
    path.open('r') do |file|
      until file.eof?
        id = file.pos / split
        target = Pathname.new(path.to_s + ".#{"%04d" % id}")
        puts "Writting to #{target}"
        target.open('w') do |file_out|
          file_out << file.read(split)
        end
      end
    end
    puts "Deleting #{path}"
    path.delete
  end
end

puts "==Generating the destination folder"
FileUtils.rm_r(temp, force: true)
FileUtils.mkdir_p(temp)
dir_size = 0
id = 0
output_name = File.join(output, Pathname.new(input).basename.to_s)
paths = Pathname.glob(File.join(input, '**', '*'))
system("ipfs repo gc")
@thread = nil
def car(temp, output_name, id)
    result = `ipfs add -r -p=false --pin=false --nocopy #{temp}`
    puts result
    ipld_map = result.lines.map do |line|
      _, cid, path = line.strip.split(' ', 3)
      [path, JSON.parse(`ipfs dag get #{cid}`)]
    end.to_h
    metadata = ipld_map.keys.map do |path|
      filename = nil
      links = []
      Pathname.new(path).ascend.each do |v|
        if filename.nil?
          filename = v.basename.to_s
        else
          links << ipld_map[v.to_s]['links'].index{|e| e['Name'] == filename}
          filename = v.basename.to_s
        end
      end
      [path, links.reverse]
    end
    cid = result.lines[-1].split(' ', 3)[1]
    File.write("#{output_name}.#{id}.txt", JSON.generate(metadata))
    File.write("#{output_name}.#{id}.cid", cid)
    system("ipfs dag export #{cid} > #{output_name}.#{id}.car")
    system("ipfs repo gc")
    FileUtils.rm_r(temp, force: true)
    FileUtils.mkdir_p(temp)
    @thread.join unless @thread.nil?
    dir_size = 0
    id = id + 1
end
paths.each do |path|
  next unless path.file?
  relative = path.relative_path_from(input)
  target = Pathname.new(temp).join(relative)
  FileUtils.mkdir_p(target.dirname.to_s)
#  FileUtils.mv(path.to_s, target.to_s)
  FileUtils.cp(path.to_s, target.to_s)
  dir_size += target.size
  if dir_size >= sector
    car(temp, output_name, id)
    @thread = Thread.new do
      system("graphsplit commP #{output_name}.#{id}.car > #{output_name}.#{id}.commP")
    end
  end
end

  if dir_size > 0
    car(temp, output_name, id)
    system("graphsplit commP #{output_name}.#{id}.car > #{output_name}.#{id}.commP")
  end
