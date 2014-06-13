#!/usr/bin/env ruby
DEBUG = 1
if DEBUG == 11
	print "Status: 200 OK\r\n"
	print "Content-Type: text/plain\r\n\r\n"
end
begin
	%w{inc/classInfo rubygems dbi inc/cmn inc/db cgi inc/sh inc/mdl inc/tmpl inc/http inc/user}.each{|f| require f}	
	PU_DIR = ENV['DOCUMENT_ROOT']
	def findMdl(request, prefix = '')
		mdl = request[0] if request
		if mdl and File.directory? 'ctrl/'+prefix+mdl
			file, mdl = findMdl(request[1..-1],prefix+mdl+'/')
		elsif mdl and File.exists? 'ctrl/'+prefix+mdl+'.rb'
			file = prefix+mdl+'.rb'
			mdl = mdl.capitalize
		elsif File.exists? 'ctrl/'+prefix+'main.rb'
			file = prefix+'main.rb'
			mdl = 'Main'
		else
			file, mdl = ['noPg.rb','noPg']
		end
		[file,mdl]
	end
	
	
	request = ENV['REQUEST_URI'].split('?')[0].split('/')[1..-1]
	file, mdl = findMdl(request)
	
	require 'mdl/'+file
	$mdl = Object.const_get(mdl+'Mdl').new
	require 'ctrl/'+file
	$ctrl = Object.const_get(mdl+'Ctrl').new
	
	$http.out
rescue Exception
	if DEBUG == 1
  	File.open('log','w').puts $!.inspect, $!.backtrace
		puts $!.inspect, $!.backtrace
		p $@
	end
end
