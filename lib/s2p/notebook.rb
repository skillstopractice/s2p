#!/usr/bin/env ruby

begin
  require "redcarpet"
rescue LoadError
  fail "The S2P::Notebook feature needs the redcarpet gem installed to run"
end

module S2P
  class Notebook
    def self.run_file(source, runner_class=NotebookRunner)
      run(File.read(source), runner_class)
    end

    def self.run(source, runner_class=NotebookRunner)
      Redcarpet::Markdown.new(runner_class, :fenced_code_blocks => true).render(source)

      :ok
    end
  end

  class Notebook
    class Component
      def self.[](*a, **o)
        new(*a, **o)
      end
    end
  end

  class NotebookRunner < Redcarpet::Render::HTML
    def codespan(code)
      case code
      when /^~ /
        eval(code[/^~ (.*)/, 1], MAIN_BINDING)
      else
        eval("puts(#{code})", MAIN_BINDING)
      end

      ""
    end

    def block_code(text, operation)
      case operation
      when nil, "ruby"
        eval(text, MAIN_BINDING) # See end of file for this hack.
      when "text"
        puts(text)
      end

      ""
    end
  end
end

S2P::NotebookRunner::MAIN_BINDING = binding
