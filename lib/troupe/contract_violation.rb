module Troupe
  class ContractViolation < StandardError
    attr_reader :context, :property

    def initialize(context=nil, opts={})
      @context = context
      @property = opts[:property]
      @message = opts[:message]
      super()
    end

    def message
      @message || "Property '#{property}' violated the interactor's contract."
    end
  end
end
