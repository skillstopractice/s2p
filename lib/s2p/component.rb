module S2P
  module Component
    def self.renderer = ApplicationController
    def self.helpers  = self.renderer.helpers

    class Buffer
      def initialize(string)
        @string = string.html_safe
      end

      def +(other) = self.class.new(@string + other.to_s)
      def to_s     = @string
    end

    module ClassMethods
      def [](*a, **o, &b) = new(*a, **o, &b)
    end

    def self.included(base)    = base.extend(ClassMethods)

    def t(template, **locals)  = renderer.render(inline: template, locals:)

    def t!(template, **locals) = renderer.render(template, locals:, layout: nil)

    def x = helpers.tag

    def o(&block) = block.binding.receiver.capture(&block)

    def +(other) = Buffer.new(to_s + other.to_s)

    def accepts_slot(block) = @_slot = block

    def capture(&block) = block.call.to_s.html_safe

    def default_template_name = "shared/#{self.class.name.underscore}"

    def helpers  = S2P::Component.helpers

    def renderer = S2P::Component.renderer

    def render_in(context) = context.render(:inline => to_html)

    def to_s = to_html

    def slot
      context = @_slot.binding.receiver

      context.capture { @_slot.call.to_s }
    end

    def to_html
      helpers.capture do
        if self.class.const_defined?(:TEMPLATE)
          t(self.class.const_get(:TEMPLATE), c: self, x: self.x )
        else
          t!(default_template_name, c: self, x: self.x )
        end
      end
    end
  end
  
  module ComponentDebugger
    def to_html
      if self.class.const_defined?(:DEBUG_TEMPLATE)
        t(self.class::DEBUG_TEMPLATE, c: self, x: self.x)
      else
        t(DEBUG_TEMPLATE, c: self, x: self.x)
      end
    end
    
    DEBUG_TEMPLATE = <<-ERB
      <div class="border border-solid p-3 border-danger">
        <strong><pre><%= c.class %></pre></strong>
        
        <% if c.respond_to?(:debugging_info) %>
          <pre><%= c.debugging_info.pretty_inspect %></pre>
        <% end %>
      </div>
    ERB
  end
end
