class User
	#require requester to be user
	def self.require
		if !$uId
			$http.relocate('/user/login')
		end
	end
end
