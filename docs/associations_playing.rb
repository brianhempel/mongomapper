
unless __FILE__ =~ /irb/
  require 'rubygems'
  require 'bundler/setup'

  $:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
  require 'mongo_mapper'
end

def reset
  [:Bird, :Feather, :Cardinal, :Sparrow, :Tree, :NewCaldonianCrow, :Tool, :Beak].each do |const|
    self.class.send(:remove_const, const) if self.class.const_defined?(const)
  end
end

# class Bird
#   include MongoMapper::Document
#   many :feathers
# end
# 
# class Feather
#   include MongoMapper::Document
# end
# 
# puts Bird.associations.keys.inspect # [:feathers]
# assoc = Bird.associations[:feathers]
# assoc.class_name # "Feather" 
# assoc.klass # Feather 
# assoc.many? # true
# assoc.one? # false 
# assoc.belongs_to? # false
# assoc.polymorphic? # false 
# assoc.as? # false 
# assoc.in_array? # false
# assoc.embeddable? # false 
# assoc.type_key_name # "_type" 
# assoc.as # :feathers 
# assoc.foreign_key # "feathers_id" 
# assoc.ivar # "@_feathers" 
# assoc.proxy_class # MongoMapper::Plugins::Associations::ManyDocumentsProxy
# 
# 
# 
# class Cardinal
#   include MongoMapper::Document
#   many :feathers
# end
# 
# class Feather
#   include MongoMapper::Document
# end
# 
# class Sparrow
#   include MongoMapper::Document
# end
# 
# Cardinal.associations.keys # ["feathers"]
# Cardinal.new.feathers # []
# Sparrow.associations = Cardinal.associations
# Sparrow.associations.keys # ["feathers"]
# Sparrow.new.feathers # NoMethodError: undefined method `feathers'
# c = Cardinal.new
# f = Feather.new
# c.feathers << f
# c.key_names
# f.key_names


# --
reset

class Bird
  include MongoMapper::Document
  many :feathers
end

class Feather
  include MongoMapper::Document
end

b = Bird.new
f = Feather.new
b.feathers << f
b.key_names
f.key_names
b.to_mongo
f.to_mongo

# --
reset

class Bird
  include MongoMapper::Document
  key :foo, Array # you have to explicitly create a :foo array for :in => foo to work
  many :feathers, :in => :foo
end

class Feather
  include MongoMapper::Document
end

b = Bird.new
f = Feather.new
b.feathers << f
b.key_names
f.key_names
b.to_mongo
f.to_mongo

# --
reset

class Bird
  include MongoMapper::Document
  many :feathers, :as => :foo
end

class Feather
  include MongoMapper::Document
end

b = Bird.new
f = Feather.new
b.feathers << f
b.key_names # ["_id"] 
f.key_names # ["_id", "foo_type", "foo_id"]
b.to_mongo # {"_id"=>BSON::ObjectId('4d019a4678fca229fd000005')}
f.to_mongo # {"_id"=>BSON::ObjectId('4d019a4678fca229fd000006'), "foo_type"=>"Bird", "foo_id"=>BSON::ObjectId('4d019a4678fca229fd000005')}

# --
reset

class Bird
  include MongoMapper::Document
  many :feathers, :polymorphic => true
end

class Feather
  include MongoMapper::Document
end

b = Bird.new
f = Feather.new
b.feathers << f
b.key_names # ["_id"]
f.key_names # ["_id", "_type", "bird_id"]
b.to_mongo # {"_id"=>BSON::ObjectId('4d01a14c78fca229fd000015')}
f.to_mongo # {"_id"=>BSON::ObjectId('4d01a14c78fca229fd000016'), "_type"=>"Feather", "bird_id"=>BSON::ObjectId('4d01a14c78fca229fd000015')}


# --
reset

class Bird
  include MongoMapper::Document
  many :feathers, :as => :foo, :polymorphic => true # doesn't work, :polymorphic overrides :as
end

class Feather
  include MongoMapper::Document
end

b = Bird.new
f = Feather.new
b.feathers << f
b.key_names # ["_id"]
f.key_names # ["_id", "_type", "bird_id"]
b.to_mongo # {"_id"=>BSON::ObjectId('4d019ad278fca229fd000007')}
f.to_mongo # {"_id"=>BSON::ObjectId('4d019ad278fca229fd000008'), "_type"=>"Feather", "bird_id"=>BSON::ObjectId('4d019ad278fca229fd000007')}


# --
reset

class Bird
  include MongoMapper::Document
  key :foo, Array
  many :feathers, :in => :foo, :polymorphic => true  # doesn't work, :polymorphic overrides :in
end

class Feather
  include MongoMapper::Document
end

b = Bird.new
f = Feather.new
b.feathers << f
b.key_names # ["_id", "foo"]
f.key_names # ["_id", "_type", "bird_id"]
b.to_mongo # {"_id"=>BSON::ObjectId('4d01a10678fca229fd000013'), "foo"=>[]}
f.to_mongo # {"_id"=>BSON::ObjectId('4d01a10678fca229fd000014'), "_type"=>"Feather", "bird_id"=>BSON::ObjectId('4d01a10678fca229fd000013')} 


# --
reset

class Bird
  include MongoMapper::Document
  many :feathers, :foreign_key => :foo
end

class Feather
  include MongoMapper::Document
end

b = Bird.new
f = Feather.new
b.feathers << f
b.key_names # ["_id"] 
f.key_names # ["_id", "foo"]
b.to_mongo # {"_id"=>BSON::ObjectId('4d01a29478fca229fd000019')}
f.to_mongo # {"_id"=>BSON::ObjectId('4d01a29478fca229fd00001a'), "foo"=>BSON::ObjectId('4d01a29478fca229fd000019')}


# --
reset

class Bird
  include MongoMapper::Document
  many :feathers, :foreign_key => :foo, :polymorphic => true
end

class Feather
  include MongoMapper::Document
end

b = Bird.new
f = Feather.new
b.feathers << f
b.key_names # ["_id"] 
f.key_names # ["_id", "_type", "foo"]
b.to_mongo # {"_id"=>BSON::ObjectId('4d01a34f78fca229fd00001b')}
f.to_mongo # {"_id"=>BSON::ObjectId('4d01a34f78fca229fd00001c'), "_type"=>"Feather", "foo"=>BSON::ObjectId('4d01a34f78fca229fd00001b')}

# --
reset

class Bird
  include MongoMapper::Document
end

class Feather
  include MongoMapper::Document
  belongs_to :bird
end

b = Bird.new
f = Feather.new
f.bird = b
b.key_names
f.key_names
b.to_mongo
f.to_mongo

# --
reset

class Bird
  include MongoMapper::Document
  many :feathers
end

class Feather
  include MongoMapper::Document
  belongs_to :bird
end

b = Bird.new
f = Feather.new
f.bird = b # b is saved to db at this point
b.key_names
f.key_names
b.to_mongo
f.to_mongo
b.feathers
f.save
b.feathers
b.reload
b.feathers

# --
reset

class Bird
  include MongoMapper::Document
  many :feathers
end

class Feather
  include MongoMapper::Document
end

b = Bird.new
f = Feather.new
b.feathers << f # both f and b are saved to the db at this point
b.key_names
f.key_names
b.to_mongo
f.to_mongo

# --
reset

class Bird
  include MongoMapper::Document
  one :tail
end

class Tail
  include MongoMapper::Document
end

b = Bird.new
t = Tail.new
b.tail = t # both t and b are saved to the db here
b.key_names # ["_id"]
t.key_names # ["_id", "bird_id"]
b.to_mongo # {"_id"=>BSON::ObjectId(...)}
t.to_mongo # {"_id"=>BSON::ObjectId(...), "bird_id"=>BSON::ObjectId(...)}

# --
reset

class Bird
  include MongoMapper::Document
  one :tail, :in => :foo # doesn't do anything
end

class Tail
  include MongoMapper::Document
end

b = Bird.new
t = Tail.new
b.tail = t # both t and b are saved to the db here
b.key_names # ["_id"]
t.key_names # ["_id", "bird_id"]
b.to_mongo # {"_id"=>BSON::ObjectId(...)}
t.to_mongo # {"_id"=>BSON::ObjectId(...), "bird_id"=>BSON::ObjectId(...)}


# --
reset

class Bird
  include MongoMapper::Document
  one :tail
end

class Tail
  include MongoMapper::EmbeddedDocument
  embedded_in :bird # makes a :bird method that returns _parent_document
end

b = Bird.new
t = Tail.new
b.tail = t # NEITHER t nor b are saved to the db yet
b.key_names # ["_id"]
t.key_names # ["_id", "bird_id"]
b.to_mongo # {"_id"=>BSON::ObjectId('4d02658a78fca229fd000041'), "tail"=>{"_id"=>BSON::ObjectId('4d02658c78fca229fd000042'), "bird_id"=>nil}}
t.to_mongo # {"_id"=>BSON::ObjectId(...), "bird_id"=>nil}
b.save


# --
reset

class Tree
	include MongoMapper::Document
	many :birds
end

class Bird
  include MongoMapper::Document
  key :name
  belongs_to :tree
end

tree = Tree.new(:birds => [Bird.new(:name => 'Jay')])
tree.birds.create!(:name => 'Wren') # <Bird ... name: "Wren" ... >
b = tree.birds.build(:name => 'House Finch') # <Bird ... name: "House Finch" ... >
b.save! # true
tree.new? # true -- the birds have been saved each time but the trees haven't
tree.birds << Bird.new(:name => 'Falcon') # []
tree.new? # false -- the concat triggers a save, I don't know why
tree.birds.size # 4

raven = Bird.new(:name => 'Raven')
raven.tree = tree # <Tree ... >
raven.save! # true
tree.birds.size # 4 -- whoops! caching
tree.birds.reload.size # 5

tree.to_mongo
# {
#   "_id" => BSON::ObjectId('...')
# }
raven.to_mongo
# {
#   "_id"     => BSON::ObjectId('...'),
#   "name"    => "Raven",
#   "tree_id" => BSON::ObjectId('...')
# }

tree.birds.where(:name => /^J/).first.name # "Jay"
# or
tree.birds.find_by_name(/^J/).name # "Jay"

class Bird
  include MongoMapper::Document
  key :name
  key :tree_id, ObjectId
  belongs_to :tree
end

# 
# hawk1 = Bird.new(:name => 'Hawk1')
# hawk2 = Bird.new(:name => 'Hawk2')
# tree.birds = [hawk1, hawk2]
# tree.birds.size # 2
# raven.reload # MongoMapper::DocumentNotFound
# Bird.count # 2

hawk1 = Bird.new(:name => 'Hawk1')
hawk2 = Bird.new(:name => 'Hawk2')
tree.birds.nullify
tree.birds = [hawk1, hawk2]
tree.birds.size # 2
raven.reload # <Bird _id: ..., name: "Raven", tree_id: nil>
Bird.count # 7



# --
reset

class Bird
  include MongoMapper::Document
  key :name
  many :feathers
end

class Feather
  include MongoMapper::EmbeddedDocument
  key :color
  embedded_in :bird
end

bunting = Bird.new(:name => 'Indigo Bunting')
bunting.feathers << Feather.new(:color => 'blue')
bunting.feathers << Feather.new(:color => 'indigo')
bunting.to_mongo # =>
{
  "_id"      => BSON::ObjectId('...'),
  "name"     => "Indigo Bunting",
  "feathers" => [
    {
      "_id"   => BSON::ObjectId('...'),
      "color" => "blue"
    },
    {
      "_id"   => BSON::ObjectId('...'),
      "color" => "indigo"
    }
  ]
}
bunting.save! # don't forget to save

bunting.feathers[0].bird.feathers[0].bird.feathers[0] # we could keep going... :)


# --
reset

# http://www.youtube.com/watch?v=TtmLVP0HvDg&NR=1

class NewCaledonianCrow
  include MongoMapper::Document
  key :name
  one :tool, :dependent => :nullify # MM currently has no default :dependent behavior for the one association, so we specify it because we don't want hard-to-track bugs :) 
end

class Tool
  include MongoMapper::Document
  key :shape
  belongs_to :new_caledonian_crow
end

smarty = NewCaledonianCrow.create(:name => "Smarty") # don't use new, we'll see why in a second 
smarty.tool? # false
tool1 = smarty.tool.create(:shape => "hook")
smarty.tool? # true
tool1.new_caledonian_crow == smarty # true -- would be nil if we used new to make smarty

smarty.to_mongo # =>
{
  "_id"  => BSON::ObjectId('...'),
  "name" => "Smarty"
}
 
tool1.to_mongo # =>
{
  "_id"   => BSON::ObjectId('...'),
  "shape" => "hook",
  "new_caledonian_crow_id" => BSON::ObjectId('...')
}

tool1.shape = "broken" # oh no it broke!
tool2 = Tool.new(:shape => "serrated") # make a new tool
smarty.tool = tool2
tool2.new_caledonian_crow? # true
tool1.reload.new_caledonian_crow? # false

tool1.to_mongo # =>
{
  "_id"   => BSON::ObjectId('...'),
  "shape" => "broken",
  "new_caledonian_crow_id" => nil
}

tool2.to_mongo # =>
{
  "_id"   => BSON::ObjectId('...'),
  "shape" => "serrated",
  "new_caledonian_crow_id" => BSON::ObjectId('...')
}


# --
reset

class Bird
  include MongoMapper::Document
  key :name
  one :beak
end

class Beak
  include MongoMapper::EmbeddedDocument
  key :type
  embedded_in :bird
end

parakeet = Bird.new(:name => 'Parakeet')
parakeet.beak? # false
parakeet.beak.build(:type => 'seed munching') # can't create embedded docs, use build
parakeet.beak? # true

parakeet.to_mongo # =>
{
  "_id"  => BSON::ObjectId('...'),
  "name" => "Parakeet",
  "beak" => {
    "_id"  => BSON::ObjectId('...'),
    "type" => "seed munching"
  }
}

parakeet.beak = Beak.new(:type => 'ferocious eagle bill')
parakeet.beak.type # "ferocious eagle bill"
parakeet.beak = nil # this is how we remove the one association
parakeet.beak? # false