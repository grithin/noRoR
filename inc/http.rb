class Http
	attr_reader :inCookies, :headers, :out, :cgi, :in, :submitted
	attr_accessor :outCookies, :headers, :out
	def getFormKey(key)
		if key =~ /^[0-9]+$/
			key.to_i
		else
			key.intern
		end
	end
	def initialize
		@cgi = CGI.new
		hash = {}
		hash.default = {}
		@in = hash #no error if ref !exist
		#parse input hashes like msg[0]=bob&msg[1]=sue
		@cgi.params.each{|k,v|
			parts = k.split('[')
			if parts.size > 1
				for i in 1...parts.size
					parts[i] = parts[i][0...-1]
					if parts[i].size < 1
						parts.delete_at(1)
					end
				end
				root = @in
				for i in 0...(parts.size - 1)
					part = getFormKey parts[i]
					if !root[part]
						root[part] = hash
					end
					root = root[part]
				end
				part = getFormKey parts[parts.size-1]
				if part.to_s[-1,1] == 'A'
					root[part] = v
				else
					root[part] = v[0]
				end
			else
				k = getFormKey k
				if k.to_s[-1,1] == 'A'
					@in[k] = v
				else
					@in[k] = v[0]
				end
			end
		}
		@submitted = false
		if !@in[:submit].empty?
			@submitted = true
		end
		@inCookies = @cgi.cookies
		@headers = {'Status'=>'200 OK','Content-Type'=>'text/html'}
		@out = ''
		@outCookies = []
	end
	
	def out
		@headers.each{|k,v| print k+': '+v+"\r\n"}
		@outCookies.each{|x| puts 'Set-Cookie: '+x.to_s+"\r\n"}
		print "\r\n"+@out
		Sh.write
	end
	def relocate(location,type=:header)
		if type == :header
			if location[0,1] == '/'
				location = 'http://'+ENV['HTTP_HOST']+location
			end
			@headers['Location'] = location
		else
			$out = '<script type="text/javascript">'
			if location.class == Fixnum
				if location == 0
					$out += 'window.location.reload( false );'
				else
					$out += 'javascript:history.go('+location+');'
				end
			else
				$out += 'document.location="'+location+'";'
			end
			$out += '</script>'
		end
		out
		exit
	end
end
$http = Http.new
Sh.read
