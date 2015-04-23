[![Code Climate](https://codeclimate.com/github/jonstokes/troupe/badges/gpa.svg)](https://codeclimate.com/github/jonstokes/troupe)

# troupe
Troupe is a contract DSL for the [interactor gem](https://github.com/collectiveidea/interactor). It's backwards-compatible with
interactor 3.1.0 and higher, so you can introduce it into your codebase gradually.

# Getting Started

Add troupe to your Gemfile and bundle install.
```ruby
gem "troupe"
```
Use it just like you would Interactor, by doing `include Troupe` in your class instead of `include Interactor`. Including the former will also include the latter by default, and monkey patch it so that it works with contracts as described below.

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
Here's a quick description of all the main verbs in the DSL:

### expects
E.g. `expects :property1, :property2`

Any properties listed here must be part of the context, or else the interactor will raise a `ContractViolation` error.

### permits
E.g. `permits :property1, :property2, default: :get_property_default`

Any attributes listed here can be part of the context and can be accessed inside the interactor as if they were local variables declared with `attr_accessor`, e.g. `puts "#{attr}"` and `self.foo = :bar`. If an attribute is part  of the context and isn't listed under `expects` or `permits`, then it has no such getter or setter.

Defaults can be set either as above, with a symbolized method name, or with a block as below:
```ruby
permits(:property1, :property2) do
   'default value'
end
```
If either `property` or `property` are when the interactor is called, then the above code will set the nil property (or properties) to 'default value'. The default applies to every listed property. If you want to set individual defaults, use separate `permits` clauses for each property.

### provides
E.g. `provides :property1, :property2, default: :get_property_default`

The `provides` verb is basically an alias for `permits`, and is offered for the sake of documentation and ease of reading.

The one nice thing about `provides` is that all post-`call` evaluations* happen in the following order: expected properties, permitted properties, provided properties. So anything declared with `provides` can expect to have anything that's expected or permitted already defined.

(* See below for what I mean by the phrase "post-`call` evaluations".)

### A word about order

The TL;DR version of this section can be expressed in two simple rules:
 1. All property defaults are lazy evaluated at the time that they're first called in the hooks or in the `call` method.
 2. Any property defaults that have not been so evaluated once the interactor is completely done will be evaluated in the order that they were declared, subject to the constraint that expected defaults go first, then permitted ones, then provided ones.

No for the longer explanation:

The default values given for the verbs above are lazy evaluated within your interactor's hooks and `call` method. So in the example above, the code `User.find(user_id)` would not be evaluated until you actually reference `user` from within `call` or one of the hooks, and then it would be evaluated only if the interactor had been called without the `:user` key in the context object.

If the `call` method ends and all the hooks are run and `user` the getter for `user` has still not been called and there still is no `user` key in the context, then an `ensure_contract_defaults` method will run and will call its getter just to ensure that it gets referenced at least once and therefore added to the context with any default that may have been set.

In other words, after the `call` and all of the hooks are run, the interactor essentially does the following:

```ruby
(expected_properties + permitted_properties + provided_properties).each do |property|
  send(property)
end
```
That call to `send(property)` just returns `context[property]` if that propert is a key in the context, otherwise it checks for a default block and tries to set the key with that.

What all of this means is that the following code is just not a problem and behaves predictably every time, provided that you call `MyInteractor` with either `property1` or `property2` set:
```ruby
class MyInteractor
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
```
Of course, if you do `MyInteractor.call` without either property key, then you'll have a stack overflow.

And again, just to be clear, you can use `expects` and `permits` and `provides` in whatever order -- it generally doesn't matter, and everything will work as you expect.

## Hooks

A contract violation will raise a `Troupe::ContractViolation` error, but it doesn't have to. You can handle violations yourself with the following hooks.

### on_violation
Example:
```ruby
class MyInteractor
  include Troupe

  expects :property1, :property2

  on_violation do |violation|
    if violation.property == :property1
      puts "Property1 violated the contract!"
    else
      context.fail!(error: violation.message)
    end
  end
end
```
The above should be self-explanatory. One thing to note: a `ContractViolation` object has a `property` method that returns the name of the property that raised the violation, and a `message` method that returns the error message that would otherwise be raised.

### on_violation_for
Example:
```ruby
class MyInteractor
  include Troupe

  expects :property1

  on_violation_for(:property1) do |violation|
    context.fail!(error: violation.message)
  end
end
```
Yep, it's technically redundant to `on_violation`, but can make the hooks a little cleaner if you're only handling one or two properties.