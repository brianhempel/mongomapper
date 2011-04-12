# == Many Belongs_to

class Tree
  include MongoMapper::Document
  many :birds
end

{
  "_id" => BSON::ObjectId('...1')
}

class Bird
  include MongoMapper::Document
  belongs_to :tree
end

{
  "_id"     => BSON::ObjectId('...2'),
  "tree_id" => BSON::ObjectId('...1')
}

{
  "_id"     => BSON::ObjectId('...3'),
  "tree_id" => BSON::ObjectId('...1')
}


# == One Belongs_to

class NewCaledonianCrow
  include MongoMapper::Document
  one :tool, :dependent => :nullify # MM currently has no default :dependent behavior for the one association, so we specify it to avoid hard-to-track bugs :) 
end

{
  "_id" => BSON::ObjectId('...4')
}

class Tool
  include MongoMapper::Document
  belongs_to :new_caledonian_crow
end

{
  "_id" => BSON::ObjectId('...5'),
  "new_caledonian_crow_id" =>
           BSON::ObjectId('...4')
}


# == Many Embedded

class Bird
  include MongoMapper::Document
  many :feathers
end

class Feather
  include MongoMapper::EmbeddedDocument
  embedded_in :bird
end

{
  "_id"      => BSON::ObjectId('...1'),
  "feathers" => [
    {
      "_id" => BSON::ObjectId('...2')
    },
    {
      "_id" => BSON::ObjectId('...3')
    }
  ]
}


# == One Embedded

class Bird
  include MongoMapper::Document
  one :beak
end

class Beak
  include MongoMapper::EmbeddedDocument
  embedded_in :bird
end

{
  "_id"  => BSON::ObjectId('...2'),
  "beak" => {
    "_id" => BSON::ObjectId('...1')
  }
}


# == Many-to-Many

class Book
  include MongoMapper::Document
  key :author_ids, Array
  many :authors, :in => :author_ids
end

{
  "_id"        => BSON::ObjectId('...3'),
  "author_ids" => [
    BSON::ObjectId('...5'),
    BSON::ObjectId('...6')
  ]
}

{
  "_id"        => BSON::ObjectId('...4'),
  "author_ids" => [
    BSON::ObjectId('...5')
  ]
}

class Author
  include MongoMapper::Document
end

{
  "_id" => BSON::ObjectId('...5')
}

{
  "_id" => BSON::ObjectId('...6')
}


# == Polymorphic Cases

# == Polymorphism on the Many Side

class Article
  include MongoMapper::Document
  many :comments, :as => :commentable
end

{
  "_id" => BSON::ObjectId('...7')
}

class Product
  include MongoMapper::Document
  many :comments, :as => :commentable
end

{
  "_id" => BSON::ObjectId('...8')
}

class Comment
  include MongoMapper::Document
  belongs_to :commentable, :polymorphic => true
end

{
  "_id"              => BSON::ObjectId('...9'),
  "commentable_type" => "Article",
  "commentable_id"   => BSON::ObjectId('...7')
}

{
  "_id"              => BSON::ObjectId('...a'),
  "commentable_type" => "Product",
  "commentable_id"   => BSON::ObjectId('...8')
}

{
  "_id"              => BSON::ObjectId('...b'),
  "commentable_type" => "Article",
  "commentable_id"   => BSON::ObjectId('...7')
}


# == Polymorphism on the Many Side with SCI

class Commentable
  include MongoMapper::Document
  many :comments, :as => :commentable
end

class Article < Commentable
end

class Product < Commentable
end

{
  "_id"   => BSON::ObjectId('...1'),
  "_type" => "Article"
}

{
  "_id"   => BSON::ObjectId('...2'),
  "_type" => "Product"
}

class Comment
  include MongoMapper::Document
  belongs_to :commentable, :polymorphic => true
end

{
  "_id"              => BSON::ObjectId('...3'),
  "commentable_type" => "Article",
  "commentable_id"   => BSON::ObjectId('...1')
}

{
  "_id"              => BSON::ObjectId('...4'),
  "commentable_type" => "Product",
  "commentable_id"   => BSON::ObjectId('...2')
}

{
  "_id"              => BSON::ObjectId('...5'),
  "commentable_type" => "Article",
  "commentable_id"   => BSON::ObjectId('...1')
}


# == Polymorphism on the Belongs_to Side with SCI

class Human
  include MongoMapper::Document
  many :favorite_things, :polymorphic => true
end

{
  "_id"=>BSON::ObjectId('...6')
}

class FavoriteThing
  include MongoMapper::Document
  belongs_to :human
end

class RaindropsOnRoses < FavoriteThing
end

{
  "_id"      => BSON::ObjectId('...7'),
  "_type"    => "FavoriteThing",
  "human_id" => BSON::ObjectId('...6')
}


# == Embedded Polymorphism

class Human
  include MongoMapper::Document
  many :favorite_things, :polymorphic => true
end

class FavoriteThing
  include MongoMapper::EmbeddedDocument
  embedded_in :human
end

class RaindropsOnRoses < FavoriteThing
end

{
  "_id"             => BSON::ObjectId('...1'),
  "favorite_things" => [
    {
      "_id"   => BSON::ObjectId('...2'),"
      _type"  => "FavoriteThing"
    },
    {
      "_id"   => BSON::ObjectId('...3'),
      "_type" => "RaindropsOnRoses"
    }
  ]
}


# == Polymorphism on both sides of one-to-many using SCI

class Liker
  include MongoMapper::Document
  many :favorite_things, :as => :liker
end

class Human < Liker
end

class SophisticatedDolphin < Liker
end

{
  "_id"   => BSON::ObjectId('...1'),
  "_type" => "Human"
}

{
  "_id"   => BSON::ObjectId('...2'),
  "_type" => "SophisticatedDolphin"
}

class FavoriteThing
  include MongoMapper::Document
  belongs_to :liker, :polymorphic => true
end

class RaindropsOnRoses < FavoriteThing
end

{
  "_id"        => BSON::ObjectId('...3'),
  "_type"      => "FavoriteThing",
  "liker_type" => "Human",
  "liker_id"   => BSON::ObjectId('...1')
}

{
  "_id"        => BSON::ObjectId('...4'),
  "_type"      => "RaindropsOnRoses",
  "liker_type" => "SophisticatedDolphin",
  "liker_id"   => BSON::ObjectId('...2')
}

{
  "_id"        => BSON::ObjectId('...5'),
  "_type"      => "RaindropsOnRoses",
  "liker_type" => "Human",
  "liker_id"   => BSON::ObjectId('...1')
}


# == Polymorphism on both sides of one-to-many with full polymorphism on the many side

class Human
  include MongoMapper::Document
  many :favorite_things, :as => :liker
end

{
  "_id" => BSON::ObjectId('...1')
}

class SophisticatedDolphin
  include MongoMapper::Document
  many :favorite_things, :as => :liker
end

{
  "_id" => BSON::ObjectId('...2')
}

class FavoriteThing
  include MongoMapper::Document
  belongs_to :liker, :polymorphic => true
end

class RaindropsOnRoses < FavoriteThing
end

{
  "_id"        => BSON::ObjectId('...3')
  "_type"      => "FavoriteThing",
  "liker_type" => "Human",
  "liker_id"   => BSON::ObjectId('...1'),
}

{
  "_id"        => BSON::ObjectId('...4')
  "_type"      => "RaindropsOnRoses",
  "liker_type" => "SophisticatedDolphin",
  "liker_id"   => BSON::ObjectId('...2'),
}

{
  "_id"        => BSON::ObjectId('...5'),
  "_type"      => "RaindropsOnRoses",
  "liker_type" => "Human",
  "liker_id"   => BSON::ObjectId('...1')
}


# == Polymorphism on both sides of many-to-may with SCI and array keys

class Animal
  include MongoMapper::Document
  key :food_ids, Array, :typecast => 'ObjectId'
  many :foods, :in => :food_ids
end

class Rat < Animal
end

{
  "_id"      => BSON::ObjectId('...6'),
  "_type"    => "Animal",
  "food_ids" => [
    BSON::ObjectId('...8')
  ]
}

{
  "_id"      => BSON::ObjectId('...7'),
  "_type"    => "Rat",
  "food_ids" => [
    BSON::ObjectId('...8'),
    BSON::ObjectId('...9')
  ]
}

class Food
  include MongoMapper::Document
end

class Garbage < Food
end

{
  "_id"   => BSON::ObjectId('...8'),
  "_type" => "Food"
}

{
  "_id"   => BSON::ObjectId('...9'),
  "_type" => "Garbage"
}


# == A MongoDB join table

class Rat
  include MongoMapper::Document
  many :animal_eats, :as => :animal
end

class Seagull
  include MongoMapper::Document
  many :animal_eats, :as => :animal
end

class AnimalEat
  include MongoMapper::Document
  belongs_to :animal, :polymorphic => true
  belongs_to :food, :polymorphic => true
end

class Garbage
  include MongoMapper::Document
  many :animal_eats, :as => :food
end

class PotatoChips
  include MongoMapper::Document
  many :animal_eats, :as => :food
end


