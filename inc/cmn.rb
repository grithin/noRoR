autoload :Tag, 'inc/tag'
class String
	def is_i
		to_s =~ /^[0-9]+$/ ? true : false
	end
end
#Default hash, key call never errors, just returns new DHash
class DHash < Hash
	alias :keyGet :[]
	def is_i
		false
	end
	def [](key)
		value = keyGet key
		if !value
			DHash.new
		else
			value
		end
	end
end
