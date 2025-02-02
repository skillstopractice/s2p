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

  class NotebookRunner < Redcarpet::Render::HTML
    def block_code(text, operation)
      case operation
      when "ruby"
        eval(text, MAIN_BINDING) # See end of file for this hack.
      else
        raise NotImplementedError
      end

      ""
    end
  end
end

S2P::NotebookRunner::MAIN_BINDING = binding
