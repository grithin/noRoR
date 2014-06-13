class Tag
	@@ignore = %w{an the is that and was}
	def self.filter(tags)
		tags.downcase.gsub(/'/,'').gsub(/[^a-z \$%#0-9_]/,' ').gsub(/[\s\n ]+/,' ').split(' ').reject{|tag| tag.empty? or tag.size < 2 or @@ignore.include? tag}
	end
	#expects filtered tag
	def self.id(tag,make=false)
		id = $db.sRow('string_id',{'string'=>tag},'id')
		if !id and make
			id = $db.in('string_id',{'string'=>tag})
		end
		id
	end
	#link tags to item
	def self.link(item,tags,table)
		link = {'item'=>item}
		uniqueTags = {}
		self.filter(tags).each{|v|
			if uniqueTags[v]
				if uniqueTags[v] < 10
					uniqueTags[v] += 1
				end
			else
				uniqueTags[v] = 0
			end
		}
		if uniqueTags.empty?
			return
		end
		tagsAdded = 0
		uniqueTags.each{|tag,add|
			if tagsAdded > 25
				break
			end
			link['s_id'] = self.id(tag,true)
			link['add'] = add
			$db.in(table,link)
			tagsAdded += 1
		}
	end
end
