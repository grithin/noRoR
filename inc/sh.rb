class Sh
	require 'digest/md5'
	$session = {}
	@@dataHash = nil
	@@sessionId = nil
	@@loc = nil
	@@time = nil
	@@write = false
	@@isUser = false
	def self.getSessionId(uId = nil)
		(0...32).map{(33 + rand(100)).chr}.join
	end
	def self.create()
		session = {}
		session['pass_key'] = self.getPassKey
		$http.outCookies << CGI::Cookie::new(
			'name'=>'passKey',
			'value'=>session['pass_key'],
			'expires'=>Time.utc('2012'),
			'path'=>'/'
			)
		@@sessionId = session['id'] = Digest::MD5.hexdigest(ENV['REMOTE_ADDR']+ENV['HTTP_USER_AGENT']+Time.now.to_f)
		$http.outCookies << CGI::Cookie::new(
			'name'=>'sessionId',
			'value'=>@@sessionId,
			'expires'=>Time.utc('2012'),
			'path'=>'/'
			)
		session['time'] = Time.now.to_i
		$db.replace('session',session)
		@@loc = 'session'
	end
	def self.login(uId)
		session = {}
		if !@@sessionId.is_a(Numeric)
			$db.del('session',@@sessionId)
		end
		session['pass_key'] = self.getPassKey
		$http.outCookies << CGI::Cookie::new(
			'name'=>'passKey',
			'value'=>session['pass_key'],
			'expires'=>Time.utc('2012'),
			'path'=>'/'
			)
		@@sessionId = session['id'] = uId
		$http.outCookies << CGI::Cookie::new(
			'name'=>'sessionId',
			'value'=>@@sessionId,
			'expires'=>Time.utc('2012'),
			'path'=>'/'
			)
		session['time'] = Time.now.to_i
		$db.replace('user_session',session)
		@@loc = 'user_session'
	end
	def self.read
		sessionId = $http.inCookies['sessionId']
		if sessionId.size > 0 and $http.inCookies['passKey'].size > 0
			#verify agent and ip
			if $http.inCookies['passKey'][0,10] == self.getPassKey(1)
				if sessionId.to_id == sessionId
					@@loc = 'user_session'
					userSession = true
				else
					@@loc = 'session'
				end
				session = $db.sRow(@@loc,sessionId)
				if session and session['pass_key'] == $http.inCookies['passKey']
					if session['data'] and session['data'].size > 0
						@@dataHash = Digest::MD5.hexdigest(session['data'])
						session['data'] = Marshal.load(session['data'])
					else
						@@dataHash = ''
					end
					if userSession
						$uId = sessionId
						@@isUser = true
					end
					@@sessionId,@@time,$session = [sessionId,session['time'],session['data']]
					@@write = true
					return
				end
			end
			$http.outCookies << CGI::Cookie::new(
				'name'=>'sessionId',
				'value'=>'',
				'expires'=>Time.utc('1960')
				)
		end
	end
	def self.write
		if @@write
			if $session.size > 0
				data = Marshal.dump($session)
				endDataHash = Digest::MD5.hexdigest(data)
			else
				data = endDataHash = ''
			end
			if endDataHash != @@dataHash
				$db.up(@@loc,{'data'=>data,:time=>Time.new.to_i},{:id=>@@sessionId})
			elsif @@time < Time.new.to_i - 86400
				$db.up(@@loc,{:time=>Time.new.to_i},{:id=>@@sessionId})
			end
		end
	end
	def self.getPassKey(part=0)
		passKey = ''
		if part != 2
			passKey += Digest::MD5.hexdigest(ENV['REMOTE_ADDR']+ENV['HTTP_USER_AGENT'])[0,10]
		end
		if part != 1
			passKey += (0...5).map{(33 + rand(100)).chr}.join
		end
	end
end
