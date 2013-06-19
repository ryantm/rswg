require_relative 'rswg'

desc "Build the site"
task :default => :build
task :build do
  build
end

desc "Update the server"
task :update do
  puts "Saving revision history"
  system "git commit -a"
  system "rsync -avz #{SITE_DIR}/. nfs:/home/public"
end

desc "Run the build task then sleep 1 second CTRL-C or CTRL-Break (Windows) to stop."
task :preview do
  while true do
    puts `rake build --trace`
    sleep 1
  end
end

task :server do
  require 'webrick'
  server = WEBrick::HTTPServer.new :Port => 3000, :DocumentRoot => SITE_DIR
  trap 'INT' do server.shutdown end
  server.start
end

task :test do
  build
  system "diff -urw #{SITE_DIR} #{File.join RSWG_DIR, "site_checkpoint"}"
end
