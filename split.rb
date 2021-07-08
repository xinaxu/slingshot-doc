#!/usr/bin/ruby
name = ARGV[0]
files = Dir.glob(File.join(name, "**", "*"))
index, size, lists, list = 0, 0, [], []
files.sort.each do |file|
  next unless File.file? file
  size += File.size(file)
  list << file
  if size > 16 * 1024 * 1024 * 1024
    lists << list
    list = []
    index += 1
    size = 0
  end
end
lists << list

lists.each_with_index do |list, index|
  tarfile = "#{name}.#{index}.tar"
  txtfile = "#{name}.#{index}.txt"
  next if File.exists?(tarfile)
  File.write(txtfile, list.join("\n"))
  puts "generating #{tarfile} with #{list.size} files #{index}/#{lists.size}"
  puts `tar -cvh -T #{txtfile} -f #{tarfile}`
end
