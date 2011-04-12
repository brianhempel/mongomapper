def reset
  [:Bird, :Feather, :Cardinal, :Sparrow, :Tree].each do |const|
    self.class.send(:remove_const, const) if self.class.const_defined?(const)
  end
end

class Bird
  include MongoMapper::Document
  many :feathers
end

class Feather
  include MongoMapper::Document
end