require 'yaml'
require 'fileutils'

require 'rubygems'
require 'bundler/setup'

require 'haml'
require 'sass'
require 'sass/plugin'

DIRECTORIES = []
DIRECTORIES << RSWG_DIR        = "./.rswg"
DIRECTORIES << SITE_DIR        = File.join(RSWG_DIR, "site")
DIRECTORIES << SOURCE_DIR      = "./src"
DIRECTORIES << ASSET_DIR       = File.join(SOURCE_DIR, "assets")
DIRECTORIES << MODEL_DIR       = File.join(SOURCE_DIR, "models")
DIRECTORIES << PAGES_DIR       = File.join(SOURCE_DIR, "pages")
DIRECTORIES << STYLESHEETS_DIR = File.join(SOURCE_DIR, "stylesheets")
DIRECTORIES << PARTIALS_DIR    = File.join(SOURCE_DIR, "partials")
DIRECTORIES << LAYOUTS_DIR     = File.join(SOURCE_DIR, "layouts")

LAST_BUILT = File.join(RSWG_DIR, "lastbuilt")

def file_write(path, data)
  FileUtils.makedirs(File.dirname(path))
  File.open(path, "w") { |f|  f << data}
end

class Array
  def drop(n)
    self[n..-1]
  end
end

def haml(string, context=Object.new, locals={},options={}, &yield_block)
  Haml::Engine.new(string, options).render(context,locals, &yield_block).chomp
end

def sass(string, context=Object.new, locals={},options={}, &yield_block)
  Sass::Engine.new(string, options).render.chomp
end

module Haml::Filters::EP
  include Haml::Filters::Base

  def render(text)
    Haml::Helpers.preserve Haml::Helpers.html_escape(text)
  end

end

def build_page(src_loc, site_loc, local_page_url, locals={})
  context = extended_context(site_loc.split("/").size - 4)
  locals  = locals.merge({:url => local_page_url}) unless locals.has_key? :url

  result = haml(File.read(src_loc), context, locals, {:filename=>src_loc})
  return if context.instance_variable_get(:@ignore)

  layout = context.instance_variable_get(:@layout)

  if layout.nil? and File.exists?("#{LAYOUTS_DIR}/default.haml")
    layout = "default"
  end

  #Loop for nested layouts
  while layout do
    context.instance_variable_set(:@layout, nil)
    result = haml(File.read("#{LAYOUTS_DIR}/#{layout}.haml"), context) {result}
    layout = context.instance_variable_get(:@layout)
  end

  puts "#{src_loc} to #{site_loc}"
  file_write(site_loc, result)
end

# The Exensions module is mixed in with every Haml context. In other words,
# the methods defined in the Extensions module are available to Haml templates
# while they are being processed.
module Extensions
  attr_accessor :nesting

  def email
    haml('%a{:href=>"mailto:&#114;y&#97;&#110;&#64;&#114;&#121;a&#110;&#116;&#109;&#46;&#99;&#111;&#109;"} &#114;y&#97;&#110;&#64;&#114;&#121;a&#110;&#116;&#109;&#46;&#99;&#111;&#109;')
  end

  def dot_dot
      "../"*nesting
  end

  def link_to(name,url,opts={})
    if url.index("http://") == 0
      href = url.strip
    else
      href = dot_dot+"#{url.strip}"
    end

    hash = {:href=>href}.merge(opts).inspect
    haml("%a#{hash} #{name.strip}")
  end

  def image_tag(url, opts={})
    if url.index("http://") == 0
      src = url.strip
    else
      src = dot_dot+"images/#{url.strip}"
    end
    hash = {:src=>src}.merge(opts).inspect
    haml("%img#{hash}/")
  end

  def render(opts={})
    p = opts.delete :partial
    filename = "#{SOURCE_DIR}/#{p}.haml"
    unless File.exists? filename
      filename = "#{SOURCE_DIR}/#{p}"
    end

    result = haml(File.read(filename), self, opts[:locals] || {}, {:filename=>filename})
    @ignore = false
    result
  end

  def stylesheet_link_tag(name)
    haml("%link{:href=>'#{dot_dot+"stylesheets/#{name}.css"}', :media=>'screen', :rel=>'stylesheet', :type=>'text/css'}/")
  end

  def model(name)
    YAML::load_file("#{MODEL_DIR}/#{name}.yaml")
  end
end

def extended_context(nesting)
  context = Object.new.extend Extensions
  context.nesting = nesting
  context
end

desc "Build the site"
task :default => :build
task :build do
  start_time = Time.now
  FileUtils.makedirs(DIRECTORIES)
  puts "Deleting #{SITE_DIR}"
  FileUtils.safe_unlink(SITE_DIR)
  puts "Copying #{ASSET_DIR}/. to #{SITE_DIR}"
  FileUtils.cp_r "#{ASSET_DIR}/.", SITE_DIR

  pages =  Dir["#{PAGES_DIR}/**/*.*", "#{PAGES_DIR}/*.*", "#{STYLESHEETS_DIR}/*.*"]
  pages.each do |page_path|
    ext = File.extname(page_path)
    local_page_url = page_path.split("/").drop(3).join("/").chomp!(ext)
    case ext
    when ".haml"
      local_page_url += ".html" unless File.basename(local_page_url).include?(".")
      site_loc = "#{SITE_DIR}/#{local_page_url}"
      build_page(page_path, site_loc, local_page_url)
    when ".sass"
      local_page_url += ".css" unless File.basename(local_page_url).include?(".")
      site_loc = "#{SITE_DIR}/stylesheets/#{local_page_url}"
      context = extended_context(page_path.split("/").size - 4)
      puts "#{page_path} to #{site_loc}"
      file_write(site_loc, sass(File.read(page_path), context, {}, {:filename=>page_path}))
    when ".hatl"
      printed_template_path = false
      model_name = File.basename(page_path, ".hatl")

      model = YAML::load_file("#{MODEL_DIR}/#{model_name}.yaml")

      model.each do |page_info|
        if page_info["path"]
          local_page_url = File.dirname(page_path).split("/").drop(3).join("/") + "/#{page_info["path"]}/index.html"
          site_loc = "#{SITE_DIR}/#{local_page_url}"
          if !printed_template_path
            puts page_path
            printed_template_path = true
          end
          puts "  " + site_loc

          build_page(page_path, site_loc, local_page_url, page_info)
        else
          puts "unspecified path for #{page_info.inspect} in #{model_name}.yaml"
        end
      end
    else
      puts "no processor for #{page_path}"
    end
  end

  puts "Build took #{Time.now-start_time} seconds."
  FileUtils.touch(LAST_BUILT)
end

desc "Update the server"
task :update do
  puts "Saving revision history"
  system "git commit -a"
  puts "rsyncing"
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
