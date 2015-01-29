# ActiveRecord::Collections

An `ActiveRecord::Collection` can best be described as being somewhere between a model (extended from `ActiveRecord::Base`), it's `ActiveRecord::Relation` and an enumerable set of records. A collection wraps and delegates to the aforementioned objects, being smart about where to send method calls and executing minimal queries only when needed (and as infrequently as possible). The latter allows for some interesting features, like the ability to build a query using all your standard scopes and the model's relation object without executing it, and serializing the query criteria to be used in a background job (instead of plucking and passing record IDs, for example). Or being able to break a collection that contains many records into smaller batches (using limited/offset collections) and traverse through them without needing to query each batch until you want to work with it.

**Highlights**
* Makes life easier by eliminating common boilerplate code when querying and working with collections of records.
* Smart about delegating methods to your model's relation object or a collection of records, with the ability to force delegation to one or the other inline.
* Executes the fewest queries possible as late as possible so nothing is queried from your database until you're ready to work with the records (or can always `load` them).
* Built-in batching and pagination makes it easy to break large result sets into smaller batches for faster querying, and makes processing batches concurrently in background jobs easy.
* Ability to serialize query criteria and re-build a collection from serialized JSON. This allows you to build your query for records as a collection and pass it to a background job without having to query for object IDs inline in an HTTP request and pass those as job arguments, for example, or to store a dynamically built query for repeat/later use.

**Lowlights**
* Grouping is not currently supported (I just haven't gotten around to it yet).
* Be careful with method overlap and delegation! The collection prefers the `ActiveRecord::Relation` when delgating method calls, so if you have a method (maybe a scope) on your relation with the same name as a method (maybe an attribute) on your model, you'll want to make sure you use `#on_records` or `#on_relation` accordingly.
* Because of the way the `ActiveRecord::Collection` behaves, it does not include the `Enumerable` module directly, and many common enumerable methods have not yet been implemented (like `select`, `reject`, etc.). If you need to use one of these methods you should call them on your collection of records directly, by grabbing an array of records with `#to_a`, or you can use `#each` or `#map` depending on your needs.
* This was prototyped in and abstracted from the Instacart rails application, and specs have not yet been ported and filled out.

## Basic Usage

TODO

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

TODO

## Serialization

TODO

## Batching

TODO

## Iterating and Manipulating

TODO
