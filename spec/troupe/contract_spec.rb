require 'spec_helper'

module Troupe
  describe Contract do

    def build_contracted(&block)
      contracted = Class.new.send(:include, Troupe)
      contracted.class_eval(&block) if block
      contracted
    end

    describe "::property" do
      it "raises an error for an invalid value for the 'presence' option" do
        expect {
          build_contracted do
            property :property, presence: :foo
          end
        }.to raise_error(RuntimeError, "Invalid value 'foo' for option presence")
      end

      it "does not raise an error if the context includes an unexpected property" do
        contracted = build_contracted do
          property :property, presence: :expected
        end
        expect { contracted.call(property: :foo, bar: 1) }.not_to raise_error
      end

    end

    context "with an on_violation_for method" do
      it "can fail the context" do
        contracted = build_contracted do
          expects :property
          on_violation_for(:property) do |violation|
            context.fail!(error: 'Property failed')
          end
        end

        interactor = contracted.call

        expect(interactor).to be_failure
        expect(interactor.error).to eq('Property failed')
      end

      it "can raise an error" do
        contracted = build_contracted do
          expects :property
          on_violation_for(:property) do
            raise "Property error"
          end
        end
        expect { contracted.call }.to raise_error(RuntimeError, "Property error")
      end
    end

    context "with an on_violation method" do
      it "can fail the context" do
        contracted = build_contracted do
          expects :property
          on_violation do |violation|
            context.fail!(error: "Property #{violation.property} failed with error: #{violation.message}")
          end
        end

        interactor = contracted.call
        expect(interactor).to be_failure
        expect(interactor.error).to eq('Property property failed with error: Expected context to include property \'property\'.')
      end

      it "can raise an error" do
        contracted = build_contracted do
          expects :property
          on_violation do |violation|
            raise "Property #{violation.property} failed with error: #{violation.message}"
          end
        end
        expect { contracted.call }.to raise_error(RuntimeError, 'Property property failed with error: Expected context to include property \'property\'.')
      end
    end

    context "with on_violation and on_violation_for methods" do
      let(:contracted) {
        build_contracted do
          expects :property, :property2

          on_violation_for(:property2) do |violation|
            context.fail!(error: 'Property2 is missing')
          end

          on_violation do |violation|
            context.fail!(error: "Property #{violation.property} failed with error: #{violation.message}")
          end
        end
      }

      it "honors the on_violation_for" do
        interactor = contracted.call(property: 'Belongs here')
        expect(interactor).to be_failure
        expect(interactor.error).to eq('Property2 is missing')
      end

      it "honors the on_violation" do
        interactor = contracted.call
        expect(interactor).to be_failure

        expect(interactor.error).to eq('Property property failed with error: Expected context to include property \'property\'.')
      end
    end

    context "is lazy evaluated" do
      let(:contracted) {
        build_contracted do
          permits :property1 do
            property2
          end

          permits :property2 do
            property1
          end

          def call
            property1
          end
        end
      }

      it "does not infinitely recurse" do
        expect { contracted.call(property2: :foo) }.not_to raise_error
      end

    end

    context "with an expects method" do
      let(:contracted) {
        build_contracted do
          expects :property
        end
      }

      it "delegates the expected method to the context object" do
        interactor = contracted.call(property: :foo)
        expect(interactor.property).to eq(:foo)
      end

      it "does not raise an error if the expected property is present but nil" do
        expect { contracted.call(property: nil) }.not_to raise_error
      end

      it "raises an error if the context doesn't include the expected property" do
        expect { contracted.call() }.to raise_error(
          Troupe::ContractViolation, "Expected context to include property 'property'."
        )
      end
    end

    context "with an permits method" do
      let(:contracted) {
        build_contracted do
          permits :property do
            :bar
          end
        end
      }

      it "accepts a block for defaults" do
        interactor = contracted.call()
        expect(interactor.property).to eq(:bar)
      end

      it "accepts a :method_name symbol as a default" do
        contracted2 = build_contracted do
          permits :property, default: :generate_property_default

          def generate_property_default
            :bar
          end
        end
        interactor = contracted2.call()
        expect(interactor.property).to eq(:bar)
      end

      it "overrides the default block with an argument" do
        interactor = contracted.call(property: :foo)
        expect(interactor.property).to eq(:foo)
      end

      it "evaluates to nil if there's no default" do
        contracted = build_contracted do
          permits :property
        end
        interactor = contracted.call()
        expect(interactor.property).to be_nil
      end

      it "passes the argument into the interactor" do
        contracted = build_contracted do
          permits :property
        end
        interactor = contracted.call(property: :foo)
        expect(interactor.property).to eq(:foo)
      end

      it "uses a block for multiple properties" do
        contracted = build_contracted do
          permits(:property1, :property2) do
            :bar
          end
        end
        interactor = contracted.call(property1: :foo)
        expect(interactor.property1).to eq(:foo)
        expect(interactor.property2).to eq(:bar)
      end
    end

    context "with a provides method" do
      it "delegates the provided getter and setter to the context object" do
        contracted = build_contracted do
          provides :property

          def call
            self.property = :foo
          end
        end

        interactor = contracted.call()
        expect(interactor.property).to eq(:foo)
      end

      it "raises a NoMethod error if you try to assign an declared or provided property" do
        contracted = build_contracted do
          provides :property

          def call
            self.bar = :foo
          end
        end

        expect { contracted.call() }.to raise_error(NoMethodError, /undefined method \`bar\=/)
      end
    end

    context "inside hooks" do
      it "works with a before hook" do
        contracted = build_contracted do

          before do
            self.property << :foo
          end

          permits(:property) { [] }
        end

        interactor = contracted.call()
        expect(interactor.property).to include(:foo)
      end

      it "works with an around hook" do
        contracted = build_contracted do

          around do |interactor|
            self.property << :foo
            interactor.call
            self.property << :bar
          end

          permits(:property) { [] }
        end

        interactor = contracted.call()
        expect(interactor.property).to include(:foo)
        expect(interactor.property).to include(:bar)
      end
    end
  end
end
