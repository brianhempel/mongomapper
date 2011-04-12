unless __FILE__ =~ /irb/
  require 'rubygems'
  require 'bundler/setup'

  $:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
  require 'mongo_mapper'
end

def reset
  [:Book, :Author, :Rat, :Seagull, :AnimalEat, :Garbage, :PotatoChips].each do |const|
    self.class.send(:remove_const, const) if self.class.const_defined?(const)
  end
end

# --

reset

class Book
  include MongoMapper::Document
  key :title
  key :author_ids, Array, :index => true
  many :authors, :in => :author_ids
end

class Author
  include MongoMapper::Document
  after_destroy :remove_from_books
  
  key :name
  
  # MM doesn't yet have a proxy to live opposite of our many in array
  # so we'll return a plucky query with a << method
  # messy eval so we can get the author id into the << method
  def books
    proxy = Book.where(:author_ids => id)
    eval <<-END
    def proxy.<<(book)
      book.save! if book.new_record?
      # see http://www.mongodb.org/display/DOCS/Updating#Updating-ModifierOperations
      Book.add_to_set({:_id => book.id}, {:author_ids => #{id.inspect}})      
    end
    END
    proxy
  end
  
  private
    def remove_from_books
      Book.pull({:author_ids => id}, {:author_ids => id})
    end
end

ruby_book = Book.new(:title => "Programming Ruby")
ruby_book.authors << Author.new(:name => "Dave Thomas")
ruby_book.authors << Author.new(:name => "Chad Fowler")
ruby_book.authors << Author.new(:name => "Andy Hunt")

ruby_book.save
ruby_book.reload.authors.map(&:name) # ["Dave Thomas", "Chad Fowler", "Andy Hunt"]

# what does it look like in the database?
ruby_book.to_mongo

dt = ruby_book.authors[0]
# what Mr. Thomas look like in the database?
dt.to_mongo

# let's play with our hacks on the Book model
dt.books.first.title # "Programming Ruby" -- our hack worked!
rails_book = Book.new(:title => "Agile Web Development with Rails")
rails_book.authors << Author.new(:name => "Sam Ruby")
rails_book.save
dt.books << rails_book
dt.reload.books.all.map(&:title) # ["Programming Ruby", "Agile Web Development with Rails"]
rails_book.reload.authors.map(&:name) # ["Dave Thomas", "Sam Ruby"]


# --

reset

class Book
  include MongoMapper::Document
  key :title
  key :author_ids, Array, :index => true
  many :authors, :in => :author_ids
end

class Author
  include MongoMapper::Document
  after_destroy :remove_from_books
  
  key :name
  
  # MM doesn't yet have a proxy to live opposite of our many in array
  # so we'll return a plucky query with a << method
  def books
    proxy = Book.where(:author_ids => id)

    def proxy.<<(book)
      book.save! if book.new_record?
      # see http://www.mongodb.org/display/DOCS/Updating#Updating-ModifierOperations
      Book.add_to_set({:_id => book.id}, {:author_ids => @author_id})      
    end    
    proxy.instance_variable_set(:@author_id, id)    
    
    proxy
  end
  
  private
    def remove_from_books
      Book.pull({:author_ids => id}, {:author_ids => id})
    end
end

ruby_book = Book.new(:title => "Programming Ruby")
ruby_book.authors << Author.new(:name => "Dave Thomas")
ruby_book.authors << Author.new(:name => "Chad Fowler")
ruby_book.authors << Author.new(:name => "Andy Hunt")

ruby_book.save
ruby_book.reload.authors.map(&:name) # ["Dave Thomas", "Chad Fowler", "Andy Hunt"]

# what does it look like in the database?
ruby_book.to_mongo

dt = ruby_book.authors[0]
# what Mr. Thomas look like in the database?
dt.to_mongo

# let's play with our hacks on the Book model
dt.books.first.title # "Programming Ruby" -- our hack worked!
rails_book = Book.new(:title => "Agile Web Development with Rails")
rails_book.authors << Author.new(:name => "Sam Ruby")
rails_book.save
dt.books << rails_book
dt.reload.books.all.map(&:title) # ["Programming Ruby", "Agile Web Development with Rails"]
rails_book.reload.authors.map(&:name) # ["Dave Thomas", "Sam Ruby"]