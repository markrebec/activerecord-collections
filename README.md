# ActiveRecord::Collections

An `ActiveRecord::Collection` can best be described as being somewhere between a model (extended from `ActiveRecord::Base`), it's `ActiveRecord::Relation` and an enumerable set of records. A collection wraps and delegates to the aforementioned objects, being smart about where to send method calls and executing minimal queries only when needed (and as infrequently as possible). The latter allows for some interesting features, like the ability to build a query using all your standard scopes and the model's relation object without executing it, and serializing the query criteria to be used in a background job (instead of plucking and passing record IDs, for example). Or being able to break a collection that contains many records into smaller batches (using limited/offset collections) and traverse through them without needing to query each batch until you want to work with it.

The implementation is nothing fancy or crazy, there is some heavy usage of delegation but not much beyond that, however I believe the concept here is very powerful. Aside from some of the benefits gained from batching, serialization and some of the other features, collections allow you to use a single object and interface to represent a set of records and use that object both to query and operate on those records.

**Highlights**
* Makes life easier by eliminating common boilerplate code when querying and working with collections of records.
* Smart about delegating methods to your model's relation object or a collection of records, with the ability to force delegation to one or the other inline.
* Executes the fewest queries possible as late as possible so nothing is queried from your database until you're ready to work with the records (or can always `load` them).
* Built-in batching and pagination makes it easy to break large result sets into smaller batches for faster querying, and makes processing batches concurrently in background jobs easy.
* Ability to serialize query criteria and re-build a collection from serialized JSON. This allows you to build your query for records as a collection and pass it to a background job without having to query for object IDs inline in an HTTP request and pass those as job arguments, for example, or to store a dynamically built query for repeat/later use.

**Lowlights**
* Be careful with method overlap and delegation! The collection prefers the `ActiveRecord::Relation` when delegating method calls, so if you have a method (maybe a scope) on your relation with the same name as a method (maybe an attribute) on your model, you'll want to make sure you use `#on_records` or `#on_relation` accordingly.
* Because of the way the `ActiveRecord::Collection` behaves, it does not include the `Enumerable` module directly, and many common enumerable methods have not yet been implemented (like `select`, `reject`, etc.). If you need to use one of these methods you should call them on your collection of records directly, by grabbing an array of records with `#to_a`, or you can use `#each` or `#map` depending on your needs.
* This was prototyped in and abstracted from the Instacart rails application, and specs have not yet been ported and filled out.

## Basic Usage

### Define a Collection

To define a collection, simply extend `ActiveRecord::Collection` and override the `initialize` method to specify which model the collection represents.

```ruby
class Thing < ActiveRecord::Base
end

class Things < ActiveRecord::Collection
  def initialize(*args)
    super(Thing, *args)
  end
end
```

**Note:** In the very near future this will likely change to something more like:

```ruby
class Things < ActiveRecord::Collection
  collection_model Thing
end
```

or possibly:

```ruby
class Things < ActiveRecord::Collection
  # we would just imply the singular model name from the plural collection name
end
```

### Query a Collection

Once you've defined your collection class, you can start using it just like your model to query for collections of records:

```ruby
Things.where(an_attribute: value).order(:other_attribute)
```

More information can be found throughout this documentation.

### Act on Results

You can easily call methods against each of the records in your collection either by using the default dynamic delegation or forcing delegation with `#on_records`.

```ruby
Things.where(attribute: value).sync_to_cache    # calls the Thing#sync_to_cache instance method on all the records in the collection
Things.where(attribute: value).other_attribute  # returns an array of other_attribute values (mapping the records if loaded, or plucking the attribute if not)
```

This becomes much more powerful when you take batching into account and consider the boilerplate code you save not having to manually iterate over each batch aggregating values or performing actions.

## Delegation

The way collections do what they do is mostly through delegation. The majority of the class is just convenience methods for wrapping the objects it represents (model, relation, records) and sending your method calls to the right one. Many important methods (such as query chain methods like `where`, `joins`, etc.) have custom definitions on the collection that know exactly what to do, but in some cases your method calls will find themselves routed through `method_missing`, at which point the collection will do it's best to send it to the right place.

Collections prefer the `ActiveRecord::Relation` when doing dynamic delegation, so if the relation responds to that method it'll get called. If the relation doesn't respond to the method, the collection attempts to route the method call to the individual records, otherwise falls back to default behavior (almost always raising a `NoMethodError`).

Keep the delegation order above in mind when calling methods and use `#on_records` or `#on_relation` where appropriate so you don't accidentally apply a scope to your query instead of retrieving an array of attributes from your records for example.

### `#on_records`

Temporarily routes all dynamic delegation to the records in the collection for inline method calls and blocks.

```ruby
  collection.on_records.do_thing                # calls do_thing on each record in the collection
  attrs = collection.on_records.some_attribute  # returns the some_attribute value for each record in an array
  collection.on_records do
    do_thing
    # self context here is the collection, which in turn routes your call to each record in the collection,
    # making this essentially the same as the first example above
  end
```

### `#on_relation`

Temporarily routes all dynamic delegation to the relation for inline method calls and blocks. This is used much more rarely than `#on_records` since the default delegation prefers the relation.

```ruby
  # pretend you have an 'available' column/attribute AND an 'available' scope on your model
  collection.on_relation.available  # calls the available scope on the collection relation
  collection.available              # same as above, default delegation prefers the relation
```

## Querying

For the most part querying with an `ActiveRecord::Collection` is just like querying with an `ActiveRecord::Relation`, which is what your model uses when you call something like `Model.where`.

The `or` method is the only query chain method with a slightly different signature:

```ruby
  MyModel.where(something).or.where(other_thing)  # ActiveRecord::Relation
  MyCollection.where(something).or(other_thing)   # ActiveRecord::Collection
```

Other than that, the rest of the query chain behaves exactly the same, and you can use `joins`, `includes`, `order`, `limit`, `where`, `not` and others, along with any scopes defined on the model to build your query criteria.

## Serialization

One of the most powerful features of active record collections is the ability to serialize your query criteria. Collections can be converted to/from a hash that describes the query criteria used to build the active record relation, and that hash can be converted to JSON and stored or passed around however you'd like.

Say you have a set of models and collections like these:

```ruby
class Serial < ActiveRecord::Base
  has_many :games
end

class Publisher < ActiveRecord::Base
  has_many :games
end

class Developer < ActiveRecord::Base
  has_many :games
end

class Game < ActiveRecord::Base
  belongs_to :developer
  belongs_to :publisher
  belongs_to :serial

  scope :by_developer_id, -> (developer_ids) { where(developer_id: developer_ids) }
  scope :by_publisher_id, -> (publisher_ids) { where(publisher_id: publisher_ids) }
  scope :by_serial_id, -> (serial_ids) { where(serial_id: serial_ids) }
end

class Games < ActiveRecord::Collection
  protected

  def initialize(*criteria)
    super(Game, *criteria)
  end
end
```

We have game series (`Serial`), individual titles/releases (`Games`), publishers and developers. A game is part of a series, and in this simple example is always developed by one developer and published by one publisher.

Here's what the hash and JSON would look like when querying a game collection by publisher and series:

```ruby
Games.by_publisher_id(1).by_serial_id(1).to_hash
# => {:select=>[], :distinct=>nil, :joins=>[], :references=>[], :includes=>[], :where=>["\"games\".\"publisher_id\" = $1", "\"games\".\"serial_id\" = $1"], :order=>[], :bind=>[{:name=>"publisher_id", :value=>1}, {:name=>"serial_id", :value=>1}]}
Games.by_publisher_id(1).by_serial_id(1).to_json
# => "{\"select\":[],\"distinct\":null,\"joins\":[],\"references\":[],\"includes\":[],\"where\":[\"\\\"games\\\".\\\"publisher_id\\\" = $1\",\"\\\"games\\\".\\\"serial_id\\\" = $1\"],\"order\":[],\"bind\":[{\"name\":\"publisher_id\",\"value\":1},{\"name\":\"serial_id\",\"value\":1}]}"
```

Now maybe you want to perform a bulk update against a collection of game records, and you expect it to be used to apply updates to large numbers of records at a time, triggered from a form or button in your web UI, so you decide to write a background job that will perform the update for you and send a notification when it's done.

You might do something like this:

```ruby
class GamesController < ApplicationController
  def bulk_update
    UpdatePublisherSerialGamesJob.perform_later(publisher.id, serial.id)
    redirect_to :back
  end
end

class UpdatePublisherSerialGamesJob < ActiveJob::Base
  def perform(publisher_id, serial_id)
    Game.by_publisher_id(publisher_id).by_serial_id(serial_id).each do |game|
      # update each game
    end
  end
end
```

But what happens when you decide you want to update games that belong to a developer and serial, rather than publisher? You can make the arguments for the job a bit more dynamic, but you'll need to edit this job every time you have a new set of criteria for which you want to apply bulk updates.

You might switch to a job that accepts `game_ids` instead of criteria arguments:

```ruby
class GamesController < ApplicationController
  def bulk_update
    UpdateGamesJob.perform_later(Game.by_publisher_id(publisher.id).by_serial_id(serial.id).pluck(:id))
    redirect_to :back
  end
end

class UpdateGamesJob < ActiveJob::Base
  def perform(game_ids)
    Game.where(id: game_ids).each do |game|
      # update each game
    end
  end
end
```

But now you have to pluck IDs from the database in order to queue up your job. This is admittedly not that heavy, but if you plan on processing large numbers of records we can do better!

```ruby
class GamesController < ApplicationController
  def bulk_update
    UpdateGamesJob.perform_later(Games.by_publisher_id(publisher.id).by_serial_id(serial.id).to_json) # this is instant, and does not query the database
    redirect_to :back
  end
end

class UpdateGamesJob < ActiveJob::Base
  def perform(game_collection)
    Games.from_json(game_collection).each do |game|
      # update each game
    end
  end
end
```

Now you can queue up a job to process millions of records in just a few milliseconds, and you can pass any game collection (or even a batch) based on whatever criteria you want to your job!

The one thing to keep in mind when serializing and passing a collection around is that it's possible the records that match your criteria will change between the time you serialize and the time you use the collection. In some cases this is good - you catch newer records that wouldn't have been caught if you'd queried and passed IDs, or you want to re-execute a query and collect results over time. In some cases it can be bad - you might want to operate on a very specific set of rows, in which case you'd probably want to query by ID anyway. But in most common uses it's likely something you won't need to think about (it behaves just like the first example job above that accepts criteria arguments).

## Batching

TODO

## Iterating and Manipulating

TODO
