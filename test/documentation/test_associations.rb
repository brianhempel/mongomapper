require 'test_helper'
require 'set'

$global_binding = binding

class Test::Unit::TestCase
  OBJECT_ID_REGEXP = /[0-9a-f]{24}/

  custom_matcher :be_like_doc do |receiver, matcher, args|
    got = receiver
    expected = args[0]
    matcher.positive_failure_message = "Expected #{expected.inspect} but got #{got.inspect}"
    keys_match = (expected.keys.to_set == got.keys.to_set)
    values_match = true
    expected.each do |k, v|
      if v.is_a?(BSON::ObjectId) && got[k].is_a?(BSON::ObjectId)
      else
        values_match = false if v != got[k]
      end
    end
    keys_match && values_match
  end

  def remove_consts(arr)
    arr.each do |const|
      $global_binding.eval "self.class.send(:remove_const, #{const.inspect})"
    end
  end
end


class AssociationsDocumentationTest < Test::Unit::TestCase
  context "the one-to-many-example" do
    setup do
      $global_binding.eval <<-END
        class Tree
          include MongoMapper::Document
          many :birds
        end

        class Bird
          include MongoMapper::Document
          key :_id, ObjectId
          belongs_to :tree
        end
      END
      
      [:Bird, :Tree].each { |c| c.to_s.constantize.collection.remove }
    end
    
    teardown do
      remove_consts [:Bird, :Tree]
    end
    
    should "pass" do      
      tree = Tree.new(:birds => [Bird.new(:name => 'Jay')])
      tree.birds.create!(:name => 'Wren')
      b = tree.birds.build(:name => 'House Finch')
      b.save!
      tree.new?.should be_true # true -- the birds have been saved each time but the trees haven't
      tree.birds << Bird.new(:name => 'Falcon')
      tree.new?.should be_false # false -- the concat triggers a save, I don't know why
      tree.birds.size.should == 4 # 4
    
      raven = Bird.new(:name => 'Raven')
      raven.tree = tree # <Tree ... >
      raven.save!.should be_true # true
      tree.birds.size.should == 4 # 4 -- whoops! caching
      tree.birds.reload.size.should == 5 # 5

      tree.to_mongo.should be_like_doc(
        {
          "_id" => BSON::ObjectId.new
        }
      )
      raven.to_mongo.should be_like_doc(
        {
          "_id"     => BSON::ObjectId.new,
          "name"    => "Raven",
          "tree_id" => BSON::ObjectId.new
        }
      )

      # class Bird
      #   include MongoMapper::Document
      #   key :name
      #   key :tree_id, ObjectId
      #   belongs_to :tree
      # end    
      lambda { Bird.key :name }.should_not raise_error
      lambda { Bird.key :tree_id, ObjectId }.should_not raise_error

      tree.birds.where(:name => /^J/).first.name # "Jay"
      # or
      tree.birds.find_by_name(/^J/).name # "Jay"
    
      # continuing our example...hawks!
      hawk1 = Bird.new(:name => 'Hawk1')
      hawk2 = Bird.new(:name => 'Hawk2')
      tree.birds = [hawk1, hawk2]
      tree.birds.size.should == 2 # 2
      raven.reload.should raise_error(MongoMapper::DocumentNotFound) # MongoMapper::DocumentNotFound
      Bird.count.should == 2 # 2
    end
    
    should "pass when nullifying" do
      tree = Tree.new(:birds => [Bird.new(:name => 'Jay')])
      tree.birds.create!(:name => 'Wren')
      b = tree.birds.build(:name => 'House Finch')
      b.save!
      tree.birds << Bird.new(:name => 'Falcon')
    
      raven = Bird.new(:name => 'Raven')
      raven.tree = tree # <Tree ... >
      raven.save!
      tree.birds.reload
    
      # let's go back and try again
      hawk1 = Bird.new(:name => 'Hawk1')
      hawk2 = Bird.new(:name => 'Hawk2')
      tree.birds.nullify
      tree.birds = [hawk1, hawk2]
      tree.birds.size.should == 2 # 2
      raven.reload.name.should == "Raven" # <Bird _id: ..., name: "Raven", tree_id: nil>
      Bird.count.should == 7 # 7
    end
  end
  
  context "the one-to-many embedded example" do
    setup do
      $global_binding.eval <<-END
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
      END
      
      [:Bird].each { |c| c.to_s.constantize.collection.remove }
    end
    
    teardown do
      remove_consts [:Bird, :Feather]
    end
    
    should "pass" do
      bunting = Bird.new(:name => 'Indigo Bunting')
      bunting.feathers << Feather.new(:color => 'blue')
      bunting.feathers << Feather.new(:color => 'indigo')
      bunting.to_mongo.should be_like_doc(
        {
          "_id"      => BSON::ObjectId.new,
          "name"     => "Indigo Bunting",
          "feathers" => [
            {
              "_id"   => BSON::ObjectId.new,
              "color" => "blue"
            },
            {
              "_id"   => BSON::ObjectId.new,
              "color" => "indigo"
            }
          ]
        }
      )
      bunting.save!.should == true # don't forget to save
    end
    
    
  end
end

