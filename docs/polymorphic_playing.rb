unless __FILE__ =~ /irb/
  require 'rubygems'
  require 'bundler/setup'

  $:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
  require 'mongo_mapper'
end

def reset
  [:Page, :Product, :Article, :Rating, :Commentable, :Comment, :Animal, :Food, :Rat, :Seagull, :AnimalEat, :Garbage, :PotatoChips, :Human, :FavoriteThing, :RaindropsOnRoses, :WhiskersOnKittens, :Liker, :SophisticatedDolphin].each do |const|
    self.class.send(:remove_const, const) if self.class.const_defined?(const)
  end
end

# --
reset

class Commentable
  include MongoMapper::Document
  many :comments, :as => :commentable
end

class Article < Commentable
end

class Product < Commentable
end

class Comment
  include MongoMapper::Document
  key :text, String
  belongs_to :commentable, :polymorphic => true
end

article = Article.create
article.comments.create(:text => "Snazzy page!")
article.save
product = Product.create
product.comments.create(:text => "It broke after a month.  But it was a good month.")
product.comments.create(:text => "Flies like a dream...until it crashes.")
product.save
article.reload.comments.count # 1 -- it worked!
product.reload.comments.count # 2 -- it worked!

# what does it look like in the database?
comment = product.comments.first
comment.to_mongo # =>
{
  "_id"              => BSON::ObjectId('...'),
  "text"             => "It broke after a month.  But it was a good month.",
  "commentable_type" => "Product",
  "commentable_id"   => BSON::ObjectId('...')
}
comment.commentable.class # Product
comment.commentable.to_mongo # =>
{
  "_id"   => BSON::ObjectId('...'),
  "_type" => "Product"
}

# does it work the other way?
new_product = Product.new
new_comment = Comment.create
new_comment.commentable = new_product
new_comment.save
new_comment.reload.commentable == new_product # true -- yay!
new_product.reload.comments.first == new_comment # true -- yay!

# --
reset

class Article
  include MongoMapper::Document
  many :comments, :as => :commentable
end

class Product
  include MongoMapper::Document
  many :comments, :as => :commentable
end

class Comment
  include MongoMapper::Document
  key :text, String
  belongs_to :commentable, :polymorphic => true
end

article = Article.create
article.comments.create(:text => "Snazzy page!")
article.save
product = Product.create
product.comments.create(:text => "It broke after a month.  But it was a good month.")
product.comments.create(:text => "Flies like a dream...until it crashes.")
product.save
article.reload.comments.count # 1 -- it worked!
product.reload.comments.count # 2 -- it worked!

# what does it look like in the database?
comment = product.comments.first
comment.to_mongo # =>
{
  "_id"              => BSON::ObjectId('...'),
  "text"             => "It broke after a month.  But it was a good month.",
  "commentable_type" => "Product",
  "commentable_id"   => BSON::ObjectId('...')
}
comment.commentable.class # Product
comment.commentable.to_mongo # =>
{
  "_id" => BSON::ObjectId('...')
}

# does it work the other way?
new_product = Product.new
new_comment = Comment.create
new_comment.commentable = new_product
new_comment.save
new_comment.reload.commentable == new_product # true -- yay!
new_product.reload.comments.first == new_comment # true -- yay!

# --
reset

class Animal
  include MongoMapper::Document
  key :name
  key :food_ids, Array, :typecast => 'ObjectId'
  many :foods, :in => :food_ids
end

class Rat < Animal
end

class Food
  include MongoMapper::Document
  key :taste
  after_destroy :remove_from_animals
  
  def animals
    Animal.where(:food_ids => id)
  end
  
  private
    def remove_from_animals
      Animal.pull({:food_ids => id}, {:food_ids => id})
    end
end

class Garbage < Food
end

# let's try it
rat = Rat.create(:name => "Nemo")
rat.foods << Garbage.new(:taste => "salty")
rat.save
garbage = rat.foods.first
garbage.taste # salty
garbage.animals.first.name # Nemo

# is the SCI loading the objects as the proper class?
garbage.animals.first.class # Rat
rat = garbage.animals.first
rat.reload.foods.first.class # Garbage

# --

reset

class Rat
  include MongoMapper::Document
  many :animal_eats, :as => :animal
end

class Seagull
  include MongoMapper::Document
  many :animal_eats, :as => :animal
end

# here's our "join table" document
# remember it's singular: AnimalEat
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

rat = Rat.create
rat.animal_eats.build(:food => Garbage.new)
rat.save
garbage = rat.animal_eats.first.food
garbage.reload
garbage.animal_eats.first.animal == rat # true

# --
reset

class Human
  include MongoMapper::Document
  many :favorite_things, :polymorphic => true
end

class FavoriteThing
  include MongoMapper::Document
  belongs_to :human
end

class RaindropsOnRoses < FavoriteThing
end

maria = Human.new
raindrops = RaindropsOnRoses.new
maria.favorite_things << raindrops
maria.save # technically the << saved it but I wouldn't count on it
maria.reload.favorite_things.first.class # RaindropsOnRoses
maria.reload.favorite_things.first == raindrops.reload # true
maria.to_mongo # =>
{
  "_id" => BSON::ObjectId('...')
}
raindrops.to_mongo # =>
{
  "_id"      => BSON::ObjectId('...'),
  "_type"    => "RaindropsOnRoses",
  "human_id" => BSON::ObjectId('4d30ea1b78fca22d49000019')
}

# --
reset

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

# and it doesn't have to inherit
class WhiskersOnKittens
  include MongoMapper::EmbeddedDocument
  embedded_in :human  
end

maria = Human.new(:favorite_things => [RaindropsOnRoses.new, WhiskersOnKittens.new])
maria.save
maria.reload.favorite_things.map(&:class) # [RaindropsOnRoses, WhiskersOnKittens]
maria.to_mongo # =>
{
  "_id" => BSON::ObjectId('...'),
  "favorite_things" => [
    {
      "_id"   => BSON::ObjectId('...'),
      "_type" => "RaindropsOnRoses"
    },
    {
      "_id"   => BSON::ObjectId('...'),
      "_type" => "WhiskersOnKittens"
    }
  ]
}


#-- 
reset

class Liker
  include MongoMapper::Document
  many :favorite_things, :as => :liker
end

class Human < Liker
end

class SophisticatedDolphin < Liker
end

class FavoriteThing
  include MongoMapper::Document
  belongs_to :liker, :polymorphic => true
end

class RaindropsOnRoses < FavoriteThing
end

maria     = Human.new
dolphin   = SophisticatedDolphin.new

raindrops1 = RaindropsOnRoses.new
raindrops2 = RaindropsOnRoses.new
favorite1  = FavoriteThing.new
favorite2  = FavoriteThing.new

# from the many side

maria.favorite_things += [raindrops1, favorite1]
maria.save
dolphin.favorite_things += [raindrops2, favorite2]
dolphin.save

maria.reload.favorite_things[0].class # RaindropsOnRoses
maria.reload.favorite_things[1].class # FavoriteThing
maria.reload.favorite_things[0] == raindrops1 # true
maria.reload.favorite_things[1] == favorite1  # true

dolphin.reload.favorite_things[0].class # RaindropsOnRoses
dolphin.reload.favorite_things[1].class # FavoriteThing
dolphin.reload.favorite_things[0] == raindrops2 # true
dolphin.reload.favorite_things[1] == favorite2  # true

# from the belongs_to side

raindrops1.reload.liker.class # Human
raindrops2.reload.liker.class # SophisicatedDolphin
more_raindrops = RaindropsOnRoses.create(:liker => maria)
more_raindrops.reload.liker == raindrops1.liker # true
maria.reload.favorite_things.include?(more_raindrops) # true

#-- 
reset

class Human
  include MongoMapper::Document
  many :favorite_things, :as => :liker
end

class SophisticatedDolphin
  include MongoMapper::Document
  many :favorite_things, :as => :liker
end

class FavoriteThing
  include MongoMapper::Document
  belongs_to :liker, :polymorphic => true
end

class RaindropsOnRoses < FavoriteThing
end

maria     = Human.new
dolphin   = SophisticatedDolphin.new

raindrops1 = RaindropsOnRoses.new
raindrops2 = RaindropsOnRoses.new
favorite1  = FavoriteThing.new
favorite2  = FavoriteThing.new

# from the many side

maria.favorite_things += [raindrops1, favorite1]
maria.save
dolphin.favorite_things += [raindrops2, favorite2]
dolphin.save

maria.reload.favorite_things[0].class # RaindropsOnRoses
maria.reload.favorite_things[1].class # FavoriteThing
maria.reload.favorite_things[0] == raindrops1 # true
maria.reload.favorite_things[1] == favorite1  # true

dolphin.reload.favorite_things[0].class # RaindropsOnRoses
dolphin.reload.favorite_things[1].class # FavoriteThing
dolphin.reload.favorite_things[0] == raindrops2 # true
dolphin.reload.favorite_things[1] == favorite2  # true

# from the belongs_to side

raindrops1.reload.liker.class # Human
raindrops2.reload.liker.class # SophisicatedDolphin
more_raindrops = RaindropsOnRoses.create(:liker => maria)
more_raindrops.reload.liker == raindrops1.liker # true
maria.reload.favorite_things.include?(more_raindrops) # true