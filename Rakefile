namespace :server do
  task :start do
    `middleman server -p 5000`
  end
end

task :ips_to_json do
  require 'json'
  ips = []
  File.open("source/data/ips.txt", "r").each_line do |line|
    ips.push line.split("\n")[0]
  end
  File.open("source/data/ips.json", "w") do |f|
    f.write(ips.to_json)
  end
end
