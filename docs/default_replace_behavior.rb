class Listing
  include MongoMapper::Document
  many :buys
  key :moo
  def moo=(val)
    raise "moo here"
  end
  belongs_to :creator, :class_name => 'User'
end

class Property
  include MongoMapper::EmbeddedDocument
  embedded_in :listing
end

class Buy < Property
  key :property_types, Array
  def property_types=(arr)
    raise "you found me!"
  end
end

# When I try to do this...

Listing.create({
  "moo"=>"haha",
"buy" => { 
"property_types"=>["SFH"]
}
})