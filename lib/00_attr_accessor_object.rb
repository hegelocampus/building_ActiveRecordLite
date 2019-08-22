require 'byebug'
class AttrAccessorObject
  def self.my_attr_accessor(*names)
    #next step is byebug!
      names.each do |name|
        debugger
        new_name = name.to_s
        if new_name.start_with?('@')
          new_name = new_name[1..-1]
        end

        define_method(new_name) do
          instance_variable_get(:@name)
        end

        define_method(new_name + "=") do |new_val|
          instance_variable_set(:@name, new_val)
        end
        
      end
    

  end
end