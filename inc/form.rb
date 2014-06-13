class Form
	def self.select(name,value,x)
		field = '<select name="'+name+'">'
		if !value.is_a? DHash
			#for numeric key
			value = value.is_i ? value.to_i : value if !value.is_a? Numeric
			field += '<option value="'+value.to_s+'">'+x[value].to_s+'</option>'
			x.delete(value)
		end
		if !x.empty?
			x.each{|v,k|
				field += '<option value="'+v.to_s+'">'+k.to_s+'</option>'
			}
		end
		field+'</select>'
	end
	def self.txt(name,value)
		value = value.to_s
		'<input type="text" name="'+name+'" '+(value.empty? ? '' : 'value="'+CGI::escapeHTML(value)+'"')+'/>'
	end
	def self.txtarea(name,value)
		value = value.to_s
		'<textarea name="'+name+'">'+(value.empty? ? '' : CGI::escapeHTML(value))+'</textarea>'
	end
end
