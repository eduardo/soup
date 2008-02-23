require 'soup'

require 'rubygems'
gem 'RedCloth'
require 'redcloth'

# This module relies on the Router model, which should define the following methods
# Router.link_to(snip_name, part=nil)
# Router.url_to(snip_name, part=nil)
# Router.edit_link(snip_name, link_text)
# Router.new_link(snip_name="New")

module Render
  def self.class_called(renderer_name)
    const_get(renderer_name)
  end

  class Base
    # Yields the appropriate renderer for the given snip. The default
    # renderer is this one (Render::Base)
    def rendering(snip, args=[])
      if renderer = snip.render_as
        yield Render.class_called(renderer).new, snip, args
      else
        yield self, snip, args
      end
    end
    
    # Handles processing the text of the content. Subclasses should
    # override this method to do fancy text processing
    def process_text(str, args)
      str
    end
    
    SNIP_REGEXP = re = %r{ \{
      (\w+) (?: \.(\w+) )?
      (?: \s+ ([\w,]+) )?
    \} }x
    
    # Default behaviour to include a snip's content
    def include_snips(snip, content, args)
      content.gsub(SNIP_REGEXP) do
        snip_name = $1
        snip_attribute = $2
        snip_args = $3 ? $3.split(',') : []
        render(snip_name, snip_attribute, snip_args)
      end
    end
    
    # Simply calls a bunch of methods, passing the result of each to the next
    def chain(snip, args, *methods)
      methods.inject(snip.content) { |content, method| send(method, snip, content, args) }
    end
    
    # Abstracted out because it might be useful to override somewhere
    def render_part(snip, part, *args)
      snip.__send__(part.to_sym)
    end
    
    # Default rendering behaviour. Subclasses shouldn't really need to touch this.
    def render(snip_name, part=nil, args=[])
      snip = Snip.find_by_name(snip_name)
      if snip
        if part
          render_part(snip, part, args)
        else
          rendering(snip, args) do |renderer, snip, args|
            renderer.chain snip, args, :process_text, :include_snips
          end
        end
      else
        "[Snip does not exist: #{Router.new_link(snip_name)}]"
      end
    rescue Exception => e
      error_for(e, snip_name, part, args)
    end
    
    def error_for(e, snip_name, part=nil, args=[])
      "[<strong>Error</strong> - " + e.message + 
      ": #{snip_name}<br/><em>Backtrace:</em><br/>#{e.backtrace.join('<br/>')}]"
    end
  end

  # Snips that render_as "Ruby" should define a class which has the instance
  # method 'handle' on it.
  # The last line of the content should be the name of that class, so that it
  # is returned by "eval" and we can instantiate it.
  # The result always has #to_s called on it.
  class Ruby < Base
    def process_text(snip, content, args)
      handler = eval(content, binding, snip.name)
      handler.new.handle(*args).to_s
    end
  end

  class Bold < Base
    def process_text(snip, content, args)
      "<b>#{content}</b>" 
    end
  end
  
  class Textile < Base
    def process_text(snip, content, args)
      RedCloth.new(content).to_html
    end
  end
  
  class Markdown < Base
    def process_text(snip, content, args)
      RedCloth.new(content).to_html(:markdown)
    end
  end
end

def snip(name, content, other_attributes={})
  snip = Snip.new(other_attributes.merge(:name => name))
  snip.content = content
  snip.save
end

# Creates a default ruby dynasnip
def dynasnip(name, code, other_attributes={:render_as => "Ruby"})
  snip(name, code, other_attributes)
end