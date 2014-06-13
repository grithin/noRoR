class Tmpl
	require 'erubis'
	attr_accessor :content, :css, :js, :json, :errors
	def initialize
		@js = []
		@css = []
		@json = {}
		@errors = {}
		@content = ''
	end
	def addMsg(type,msg)
		if !@json['msgs']
			@json['msgs'] = {}
			@json['msgs'][type] = []
		elsif !@json['msgs'][type]
			@json['msgs'][type] = []
		end
		@json['msgs'][type] << msg
	end
	def clearMsg(type,clear=nil)
		if !@json['msgs']
			@json['msgs'] = {}
			@json['msgs']['clear'] = {}
		elsif !@json['msgs']['clear']
			@json['msgs']['clear'] = {}
		end
		
		if type == 'all'
			@json['msgs']['clear']['all'] = 1
		else
			if ! @json['msgs']['clear'][type]
				@json['msgs']['clear'][type] = []
			end
			@json['msgs']['clear'][type] << clear
		end
	end
	def get(file)
		if file.class == Array
			file.each{|f|
				@content = Erubis::Eruby.new(File.read('tmpl/'+f+'.tpl')).result($mdl.bound)
			}
		else
			@content = Erubis::Eruby.new(File.read('tmpl/'+file+'.tpl')).result($mdl.bound)
		end
		return @content
	end
	def out(file)
		$http.out = get(file)
	end
	def mapErrors(errors=nil)
		if !errors
			errors = @errors
		end
		if $mdl.errors
			$mdl.errors.each{|k,v|
				if errors[k] and errors[k][v]
					if !errors[k][v]['name']
						errors[k][v]['name'] = k
					end
					$tmpl.addMsg('error',errors[k][v])
				end
			}
		end
	end
end
$tmpl = Tmpl.new
