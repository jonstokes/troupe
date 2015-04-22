require "interactor"
require "troupe/version"
require "troupe/contract_violation"
require "troupe/contract"
require "troupe/contract/property"
require "troupe/contract/property_table"

module Troupe
  def self.included(base)

    Interactor::Context.class_eval do
      def members
        @table.keys
      end
    end

    Interactor.class_eval do
      def run!
        with_hooks do
          validate_contract_expectations
          call
          ensure_contract_defaults
          check_each_violation
          context.called!(self)
        end
      rescue
        context.rollback!
        raise
      end
    end

    base.class_eval do
      include Interactor
      include Contract
    end
  end
end
