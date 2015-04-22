# troupe
Troupe is a contract DSL for the interactor gem.

# Requirements
Ruby 2.0 or higher

# DSL

Here's the normal way to write an interactor:
```ruby
class PlaceOrder
  include Interactor

  before do
    context.user ||= User.find(context.user_id)
  end

  def call
    context.order = context.user.orders.create(context.attributes)

    context.fail! unless context.order.persisted?
  end
end
```

Here's the same interactor using the DSL
```ruby
class PlaceOrder
  include Troupe

  expects :attributes
  permits :user_id

  permits(:user) do
    User.find(user_id)
  end

  provides(:order) do
    user.orders.create(attributes)
  end

  before { context.fail! unless order.persisted? }
end
```

Here's a quick description of all the verbs in the DSL:

### expects
E.g. `expects :property1, :property2`

Any properties listed here must be part of the context, or else the interactor will raise a `ContractViolation` error.

### permits
E.g. `permits :property1, :property2, default: :get_property_default`

Any attributes listed here can be part of the context and can be accessed inside the interactor as if they were
 local variables declared with `attr_accessor`, e.g. `puts "#{attr}"` and `self.foo = :bar`. If an attribute is part
 of the context and isn't listed under `expects` or `permits`, then it has no such getter or setter.

Defaults can be set either as above, with a symbolized method name, or with a block as below:
```ruby
permits(:property1, :property2) do
   'default value'
end
```
If either `property` or `property` are when the interactor is called, then the above code will set the nil property (or properties)
to 'default value'. The default applies to every listed property. If you want to set individual defaults, use separate `permits` clauses for
 each property.

### provides
E.g. `provides :property1, :property2, default: :get_property_default`

The `provides` verb is basically an alias for `permits`, and is offered for the sake of documentation and ease of reading.

The one nice thing about `provides` is that all post-`call` evaluations happen in the following order: expected properties,
permitted properties, provided properties. So anything declared with `provides` can expect to have anything that's
expected or permitted already defined.

### A quick word about order
Now, above I said "post-`call` evaluations". What I mean by that is the following: the default values given for the verbs
above are lazy evaluated within the interactor's `call` method. So in the example above, the code `User.find(user_id`)` would
not be evaluated until you actually call `user` from within `call` or one of the hooks, and then it would be evaluated only if the interactor
had been called without the `:user` key in the context object. If the `call` method ends and all the hooks are run and `user` is still `nil`,
then an `ensure_contract_defaults` method will run and try to call any `default` blocks or methods
that have been set for that property.

Ok, back to the DSL...

### on_violation
/Description needed/

### on_violation_for
/Description needed/