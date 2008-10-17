require 'rubygems'
require 'rake'
require 'haml'
require 'sass'
require 'sass/plugin'

require 'hpricot'
require 'yaml'

task :default => :build

def file_write(path, data)
  File.send(:makedirs, File.dirname(path))
  File.open(path, "w") { |f|  f << data}
end

class RSSify

  def initialize(path, options={})
    full_path = File.expand_path(path)

    if !File.exists?(full_path)
      raise "#{full_path} does not exist."
    end

    if !File.directory?(full_path)
      raise "#{full_path} is not a directory."
    end

    entry_paths = Dir.glob(full_path+"/*.html")

    config = YAML::load_file(full_path+"/rssify.yml") || (raise "I need an rssify.yml file in #{full_path}")

    feed = config['feed']

    entries = entry_paths.map do |entry_path|
      if !entry_path.include? "index.html"
        html = File.read(entry_path)
        doc = Hpricot(html)

        publishedElement = doc.at('.published')
        if publishedElement
          pubDate = DateTime.strptime(publishedElement['title'])
        else
          pubDate = DateTime.now
        end

        link = config['docroot'] + "/" + File.basename(entry_path)

        {
          :entry_path => "pages/"+entry_path.split("/")[5..-1].join("/").chomp(".html"),
          :url     => entry_path.split("/")[5..-1].join("/"),
          :guid    => link,
          :link    => link,
          :comments=> link+"#comments",
          :title   => doc.at('head/title').inner_html,
          :pubDate => pubDate,
          :author => feed['author'],
          :description => doc.at('.main')
        }
      else
        nil
      end
    end.compact.sort_by {|entry| entry[:pubDate]}.reverse

    eng = Haml::Engine.new(File.read("./rss.haml"), {:filename=>"./rss.haml"})
    result = eng.render(Object.new, {:feed=>feed, :entries=>entries})
    file_write("./site/blog/rss.xml", result)

    eng = Haml::Engine.new(File.read("./archive.haml"),{:filename=>"./archive.haml"})
    result = eng.render((context=extended_context(2)), {:feed=>feed, :entries=>entries})
    layout = context.instance_variable_get(:@layout) || "default"
    final_result = haml(File.read("./src/layouts/#{layout}.haml"), context) {result}
    file_write("./site/blog/archives/index.html", final_result)

    eng = Haml::Engine.new(File.read("./index.haml"),{:filename=>"./index.haml"})
    result = eng.render((context=extended_context(1)), {:feed=>feed, :entries=>entries})
    layout = context.instance_variable_get(:@layout) || "default"
    final_result = haml(File.read("./src/layouts/#{layout}.haml"), context) {result}
    file_write("./site/blog/index.html", final_result)
  end

end


def haml(string, context=Object.new, locals={},options={}, &yield_block)
  Haml::Engine.new(string, options).render(context,locals, &yield_block).chomp
end

def sass(string, context=Object.new, locals={},options={}, &yield_block)
  Sass::Engine.new(string, options).render.chomp
end


module Extensions

  attr_accessor :nesting

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
      src = url
    else
      src = dot_dot+"images/#{url}"
    end
    hash = {:src=>src}.merge(opts).inspect
    haml("%img#{hash}/")
  end

  def render(opts={})
    p = opts.delete :partial
    filename = "./src/#{p}.haml"
    haml(File.read(filename), self, opts[:locals] || {}, {:filename=>filename})
  end

  def stylesheet_link_tag(name)
    haml("%link{:href=>'#{dot_dot+"stylesheets/#{name}.css"}', :media=>'screen', :rel=>'stylesheet', :type=>'text/css'}/")
  end

end

def extended_context(nesting)
  context = Object.new.extend Extensions
  context.nesting = nesting
  context
end

desc "Build the site"
task :build do
  layout_mtime = Dir["./src/layouts/*.haml","./src/partials/*.haml", "Rakefile"].map{|path| File.mtime(path)}.sort.reverse.first
  puts "layouts/partials last changed: #{layout_mtime}"

  pages =  Dir["./src/pages/**/*.haml"] +Dir.glob("./src/pages/*.haml")

  pages.each do |page|

    local_page_url = page.split("/")[3..-1].join("/").chomp(".haml")+'.html'
    site_loc = "./site/#{local_page_url}"
    next if File.exists?(site_loc) and File.mtime(site_loc) > File.mtime(page) and File.mtime(site_loc) > layout_mtime

    context = extended_context(page.split("/").size - 4)
    puts page
    result = haml(File.read(page), context, {:url=>local_page_url}, {:filename=>page})
    layout = context.instance_variable_get(:@layout) || "default"
    puts context.instance_variables.inspect
    final_result = haml(File.read("./src/layouts/#{layout}.haml"), context) {result}

    puts site_loc
    file_write(site_loc, final_result)
  end


  pages =  Dir.glob("./src/stylesheets/*.sass")
  pages.each do |page|
    site_loc = "./site/#{page.split("/")[2..-1].join("/").chomp(".sass")+'.css'}"
    next if File.exists?(site_loc) and File.mtime(site_loc) > File.mtime(page)

    context = extended_context(page.split("/").size - 4)

    final_result = sass(File.read(page), context, {}, {:filename=>page})
    puts site_loc
    file_write(site_loc, final_result)
  end


  RSSify.new("./site/blog")
end

desc "Update the server"
task :update do
  puts "rsyncing"
  system("rsync -avz site/. nfs:/home/public")
end


task :preview do
  while (true) do
    `rake build --trace`
    sleep 1
  end
end
