require_relative 'rswg'
require 'guard'

desc "Build the site"
task :default => :build
task :build do
  RSWG.build
end

desc "Update the server"
task :update do
  puts "Saving revision history"
  system "git commit -a"
  system "rsync -avz #{SITE_DIR}/. nfs:/home/public"
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
