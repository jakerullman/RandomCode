# Will keep all passed in attributes in the `attributes` attribute
# But will allow you to pull out certain attributes that you want as
# getters and setters. Great for accessing with `random_object.some`

class RandomObject
  WANTED_ATTRS = [:some, :attrs, :you, :want]
 
  attr_accessor :attributes, *WANTED_ATTRS
 
  def initialize(attrs)
    self.attributes = attrs
    attrs.each { |key, val| send("#{key}=", val) if WANTED_ATTRS.include?(key) }
  end
end