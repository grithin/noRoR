class Mdl
	attr_accessor :content, :css, :js, :json, :in, :errors
	def initialize
		@errors = {}
	end
	def bound
		binding
	end
end
