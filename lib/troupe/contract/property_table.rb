module Troupe
  module Contract
    class PropertyTable
      def initialize
        @table ||= {}
      end

      def get(property_name)
        @table[property_name]
      end

      def set(property_name, opts={})
        @table[property_name] ||= Property.new(opts)
        @table[property_name].merge!(opts)
      end

      def each_property
        @table.each do |property_name, property|
          yield property_name, property
        end
      end

      def select(args)
        @table.select do |_, property|
          args == args.select do |k, v|
            property.send(k) == v
          end
        end
      end

      def expected;  select(presence: :expected); end
      def permitted; select(presence: :permitted); end
      def provided;  select(presence: :provided); end

      def all_properties
        expected_properties +
          permitted_properties +
          provided_properties
      end

      def expected_properties; expected.keys; end
      def permitted_properties; permitted.keys; end
      def provided_properties; provided.keys; end

      def expected_and_permitted_properties
        expected_properties + permitted_properties
      end

      def undeclared_properties(context)
        context.members.select do |attr|
          !expected_and_permitted_properties.include?(attr)
        end
      end

      def missing_properties(context)
        expected_properties.select do |attr|
          !context.members.include?(attr)
        end
      end

      def default_for(property_name)
        @table[property_name].default
      end
    end
  end
end