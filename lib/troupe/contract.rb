module Troupe
  module Contract
    VALID_TYPES = %i(open closed)

    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end

      private

      def violation_table
        @violation_table ||= {}
      end

      def validate_contract_expectations
        populate_violation_table
        check_each_violation
      end

      def missing_properties
        @missing_properties ||= self.class.missing_properties(context)
      end

      def ensure_contract_defaults
        self.class.all_properties.each do |attr|
          send(attr)
        end
      end

      def populate_violation_table
        missing_properties.each do |property_name|
          violation_table[property_name] = ContractViolation.new(
            self,
            property: property_name,
            message: "Expected context to include property '#{property_name}'."
          )
        end
      end

      def check_each_violation
        return if violation_table.empty?
        violation_table.each do |property_name, violation|
          if block = violation_block_for(property_name)
            instance_exec(violation, &block)
          else
            raise violation
          end
        end
      end

      def violation_block_for(property_name)
        self.class.violation_block_for(property_name) ||
          self.class.on_violation_block
      end
    end

    module ClassMethods
      # Core DSL
      #
      def property(attr, opts={}, &block)
        opts.merge!(default: block) if block
        property_table.set(attr, opts)

        delegate_properties
      end

      def on_violation_for(*args, &block)
        args.each do |arg|
          next unless property = property_table.get(arg)
          property.on_violation = block
        end
      end

      def on_violation(&block)
        @on_violation_block = block
      end

      # Sugar for core DSL
      #
      def expects(*args, &block)
        presence_is(:expected, args, block)
      end

      def permits(*args, &block)
        presence_is(:permitted, args, block)
      end

      def provides(*args, &block)
        presence_is(:provided, args, block)
      end

      def on_violation_block
        @on_violation_block
      end

      def expected_properties;  property_table.expected_properties; end
      def permitted_properties; property_table.permitted_properties; end
      def provided_properties;  property_table.provided_properties; end
      def all_properties;       property_table.all_properties; end
      def default_for(attr);    property_table.default_for(attr); end
      def violation_block_for(attr);     property_table.get(attr).on_violation; end
      def missing_properties(context);   property_table.missing_properties(context); end

      def expected_and_permitted_properties
        property_table.expected_and_permitted_properties
      end

      private

      def property_table
        @property_table ||= PropertyTable.new
      end


      def delegate_properties
        all_properties.each do |attr|
          define_method attr do
            next context[attr] if context.members.include?(attr)
            default = self.class.default_for(attr)
            context[attr] = if default.is_a?(Proc)
                              instance_exec(&default)
                            elsif default.is_a?(Symbol)
                              send(default)
                            end
          end

          define_method "#{attr}=" do |value|
            context[attr] = value
          end
        end
      end

      def presence_is(presence, args, block)
        opts = args.detect { |arg| arg.is_a?(Hash) } || {}
        opts.merge!(presence: presence)
        args.reject! { |arg| arg.is_a?(Hash) }

        args.each do |arg|
          property(arg, opts, &block)
        end
      end
    end
  end
end