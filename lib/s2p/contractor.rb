module S2P
  class Contractor
    def self.for(description)
      new(description)
    end

    def self.[](description)
      self.for(description)
    end

    def self.disable_enforcement
      @conditions_disabled = true
    end

    def self.conditions_disabled?
      !!( @conditions_disabled  || ENV["SKIP_CONTRACT_ENFORCEMENT"] )
    end

    def initialize(description)
      @description  = description
      @assumptions  = []
      @assurances   = []
      @observations = {}
      @context      = ""
    end

    def watches(name, &b)
      @observations[name] = { action: b }

      self
    end

    attr_reader :observations

    def acknowledges(context)
      @context << "[#{context}]"

      self
    end

    def broken(message)
      raise message unless self.class.conditions_disabled?
    end

    def __fixme__
      broken("Not implemented yet")
    end

    def assumes(description, &b)
      @assumptions << [description, b]

      self
    end

    def ensures(description, &b)
      @assurances << [description, b]

      self
    end

    def work(*)
      return yield(*) if self.class.conditions_disabled?

      @assumptions.each do |description, condition|
        if @context != ""
          fail "Failed expectation: [when #{@context}] #{description} (in #{@description})" unless condition.call(*)
        else
          fail "Failed expectation: #{description} (in #{@description})" unless condition.call(*)
        end
      end

      @observations.each do |message, diff|
        diff[:before] = diff[:action].call
      end

      result = yield(*)

      @observations.each do |message, diff|
        diff[:after] = diff[:action].call
      end

      @assurances.each do |description, condition|
        if @context != ""
          fail "Failed expectation: #{@context} #{description} (in #{@description})" unless condition.call(result, observations)
        else
          fail "Failed expectation: #{description} (in #{@description})" unless condition.call(result, observations)
        end
      end

      result
    end
  end
end
