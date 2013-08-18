require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'fileutils'
require 'haml'
require 'tilt'

Tilt.register Tilt::HamlTemplate, 'hatl'

DIRECTORIES = []
DIRECTORIES << RSWG_DIR        = "./.rswg"
DIRECTORIES << SITE_DIR        = File.join(RSWG_DIR, "site")
DIRECTORIES << SOURCE_DIR      = "./src"
DIRECTORIES << ASSET_DIR       = File.join(SOURCE_DIR, "assets")
DIRECTORIES << MODEL_DIR       = File.join(SOURCE_DIR, "models")
DIRECTORIES << PAGES_DIR       = File.join(SOURCE_DIR, "pages")
DIRECTORIES << PARTIALS_DIR    = File.join(SOURCE_DIR, "partials")
DIRECTORIES << LAYOUTS_DIR     = File.join(SOURCE_DIR, "layouts")
LAST_BUILT = File.join(RSWG_DIR, "lastbuilt")

module Haml::Filters::EP
  include Haml::Filters::Base
  def render(text)
    Haml::Helpers.preserve Haml::Helpers.html_escape(text)
  end
end

class Array
  def drop(n)
    self[n..-1]
  end
end

def haml(string, context=Object.new, locals={},options={}, &yield_block)
  Haml::Engine.new(string, options).render(context,locals, &yield_block).chomp
end

# The Exensions module is mixed in with every Haml context. In other words,
# the methods defined in the Extensions module are available to Haml templates
# while they are being processed.
module Extensions
  attr_accessor :nesting

  def email
    '<a href="mailto:ryan@ryantm.com">ryan@ryantm.com</a>'
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
    filename = "#{SOURCE_DIR}/#{p}.html.haml"
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

module RSWG
  def RSWG.file_write(path, data)
    FileUtils.makedirs(File.dirname(path))
    File.open(path, "w") { |f|  f << data}
  end

  def RSWG.build_page(src_loc, site_loc, local_page_url, locals={})
    context = extended_context(site_loc.split("/").size - 4)
    locals  = locals.merge({:url => local_page_url}) unless locals.has_key? :url

    template = Tilt.new(src_loc)
    result = template.render(context, locals)
    return if context.instance_variable_get(:@ignore)

    if (template.is_a? Tilt::HamlTemplate)
      layout = context.instance_variable_get(:@layout)

      if layout.nil? and File.exists?("#{LAYOUTS_DIR}/default.html.haml")
        layout = "default"
      end

      #Loop for nested layouts
      while layout
        context.instance_variable_set(:@layout, nil)
        template = Tilt.new("#{LAYOUTS_DIR}/#{layout}.html.haml")
        result = template.render(context, locals) {result}
        layout = context.instance_variable_get(:@layout)
      end
    end

    file_write(site_loc, result)
  end

  def RSWG.extended_context(nesting)
    context = Object.new.extend Extensions
    context.nesting = nesting
    context
  end

  def RSWG.build
    start_time = Time.now
    FileUtils.makedirs DIRECTORIES
    FileUtils.rm_rf SITE_DIR
    FileUtils.cp_r "#{ASSET_DIR}/.", SITE_DIR

    Dir["#{PAGES_DIR}/**/*.*"].each do |page_path|
      ext = File.extname(page_path)
      local_page_url = page_path.split("/").drop(3).join("/").chomp!(ext)
      case ext
      when ".haml", ".sass", ".scss"
        site_loc = "#{SITE_DIR}/#{local_page_url}"
        build_page(page_path, site_loc, local_page_url)
      when ".hatl"
        model_name = File.basename(page_path, ".hatl")
        model = YAML::load_file("#{MODEL_DIR}/#{model_name}.yaml")
        model.each do |page_info|
          if page_info["path"]
            local_page_url = File.dirname(page_path).split("/").drop(3).join("/") + "/#{page_info["path"]}/index.html"
            site_loc = "#{SITE_DIR}/#{local_page_url}"
            build_page(page_path, site_loc, local_page_url, page_info)
          else
            puts "unspecified path for #{page_info.inspect} in #{model_name}.yaml"
          end
        end
      else
        puts "no processor for #{page_path}"
      end
    end

    FileUtils.touch(LAST_BUILT)
    puts "Build took #{Time.now-start_time} seconds."
  end
end
