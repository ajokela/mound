rabl
====

Ruby bulk loader, with clever foreign key support. RABl was developed with funding from the National Science Foundation, and is provided via a [BSD 3-clause like license](http://www.opensource.org/licenses/BSD-3-Clause), see [LICENSE](https://github.com/mnpopcenter/rabl/blob/master/LICENSE) for specifics.

Quick Tutorial
===
RABL deals with data described via YAML, and uses your ActiveRecord models to load the data. Assuming you have an ActiveRecord model class named `invoice_type`, with an attribute named `name`, like so:

```ruby
class InvoiceType < ActiveRecord::Base
  attr_accessible :name
end
```

then you could populate the table with three records like this:

    invoice_types:
      -
        name: cash
      -
        name: credit
      -
        name: singleton

Internally, RABL will create three instances of the invoice_type model and save them. The usual active record behaviour applies, in that you'll also have an id column on your model and AR or the database will assign an arbitrary primary key for you.

This is useful, but not that different from what you can do with fixtures. Things get more interesting when you have data with relationships. Let's consider adding an `invoice` model as well. Each `invoice`, of course, has an `invoice_type` to go with it.

Here's our invoice.rb class:
```ruby
class Invoice < ActiveRecord::Base
  belongs_to :invoice_type
  attr_accessible :description, :price
end
```

and we'll need to update invoice_type.rb to reflect the one-to-many relationship:
```ruby
class InvoiceType < ActiveRecord::Base
  attr_accessible :name
  has_many :invoices
end
```

Now, the invoice_type import file doesn't change, but we can also load invoices and set up the foreign key properly by referring to the invoice_type by name, like so:

    invoices:
      - 
        name: one
        description: basic
        price: 9.99
        invoice_type_id: cash
      - 
        name: two
        description: with child items
        price: 19.99
        invoice_type_id: credit
      -
        name: highlander
        description: Why is this named highlander? Beacuse there should only be one.
        price: 0.00
        invoice_type_id: singleton



