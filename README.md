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
