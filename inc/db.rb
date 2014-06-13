require 'dbi'
class Db
	@@dbs = {}
	@@db = nil
	attr_accessor :debug
	def connect
		@@db = DBI.connect('DBI:'+@conInfo[:type]+':'+@conInfo[:db],@conInfo[:user],@conInfo[:pass])
	end
	def disconnect
		if @sth and !@sth.finished?
			@sth.finish
		end
		@@db.disconnect
	end
	def initialize(x)
		@conInfo = x
		@sth = nil
		@debug = false
	end
	def self.init(x)
		if x[:name]
			x[:name] == :default
		end
		if !@@dbs[x[:name]]
			@@dbs[x[:name]] = Db.new(x)
		else
			@@dbs[x[:name]]
		end
	end
	def quote(x)
		if !@@db
			connect
		end
		if @conInfo[:type] == 'sqlite3'
			if x.class == String
				'\''+x.gsub( /'/, "''" )+'\''
			else
				x
			end
		else
			@@db.quote(x)
		end
	end
	def q(sql)
		if !@@db
			connect
		end
		if @sth and !@sth.finished?
			@sth.finish
		end
		begin
			if @debug
				puts sql
			end
			@sth = @@db.prepare(sql)
			@sth.execute
			@sth
		rescue Exception
			puts sql
			puts $!.inspect, $!.backtrace
			exit
		end
	end
	def qRow(sql)
		if hash = q(sql+' limit 1').fetch_hash
			hash.size == 1 ? hash.values[0] : hash
		end
	end
	def qRows(sql)
		hashes = []
		q(sql).fetch_hash{|hash|
			hashes << hash
		}
		hashes
	end
	def qList(sql)
		hash = q(sql).fetch_array
	end
	def qCol(sql)
		column = []
		q(sql).fetch_array{|array|
			column << array[0]
		}
		column
	end
	def qColKey(sql,col=nil)
		sth = q(sql)
		row = sth.fetch_hash
		if not col
			col = row.keys[0]
		end
		rows = {}
		if row.size == 2
			loop{
				key = row[col]
				row.delete(col)
				rows[row[col]] = row.values[0]
				break unless row = sth.fetch_hash
			}
		else
			key = row[col]
				row.delete(col)
				rows[row[col]] = row
				break unless row = sth.fetch_hash
		end
	end
	def up(table,up,where)
		q('update "'+table+'" set '+ktvf(up).join(', ')+where(where)).rows
	end
	def del(table,where)
		q('delete from "'+table+'"'+where(where)).rows
	end
	def sel(from,where,columns='*')
		from = '"'+(from.class == Array ? from.join('", "') : from)+'"'
		if columns.class == Array
			columns = columns.map{|v| '"'+v+'"'}.join(', ')
		end
		if where.class == Hash
			where = where(where)
		elsif where.is_a?(Numeric)
			where = ' where id = '+where.to_s
		else
			where = ' where '+where
		end
		sql = 'select '+columns+' from '+from+where
	end
	def sRow(*args)
		qRow(sel(*args))
	end
	def sRows(*args)
		qRows(sel(*args))
	end
	def into(type,table,kvA,update='')
		if !@@db
			connect
		end
		returnId = false
		@@db.columns(table).each{|x| returnId = true if x['name'] =='id'}
		q(type+' INTO "'+table+'" '+kvf(kvA)+update)
		if returnId
			inFunc = @conInfo[:type]+'Into'
			Db.instance_method(inFunc.intern).bind(self).call(table)
		end
	end
	def in(table,kvA,ignore=nil)
		into('INSERT '+(ignore ? 'IGNORE':''), table, kvA)
	end
	def inUp(table,kvA,update='')
		if !update
			update = ktvf(kvA)
		end
		into('INSERT',table,kvA,'ON DUPLICATE KEY UPDATE '+update)
	end
	def replace(table,kvA)
		info('REPLACE',table,kvA)
	end
	def pgInto(table)
		seq = table+'_id_seq'
		if sRow('pg_class',{'relname'=>seq},'1')
			q('select currval('+quote(seq)+') as last').fetch_hash.values[0]
		end
	end
	def sqlite3In(table)
		q('select last_insert_rowid() as last').fetch_hash.values[0]
	end
	#key to value formatter
	def ktvf(kvA)
		formatted = []
		kvA.each{|k,v|
			if k.class == Symbol
				k = k.to_s
			elsif k[0,1] == ':'
				k = k[1..-1]
			else
				v = quote(v)
			end
			if match = k.match(/(^[^?]+)\?([^?]+)$/)
				k = match[2]
				equator = match[1]
			elsif
				equator = '='
			end
			formatted << '"'+k+'" '+equator+' '+v
		}
		formatted
	end
	def where(where)
		if where.class == Hash
			where = ktvf(where).join(' and ')
		elsif !where
			return
		elsif where !=~ / /
			if !where.is_a?(Numeric)
				where = quote(where)
			end
			where = 'id = '+where.to_s
		end
		' where '+where.to_s
	end
	#key value formatter
	def kvf(kvA)
		keys, values = [[],[]]
		kvA.each{|k,v|
			if k.class == Symbol
				k = k.to_s
			elsif k[0,1] == ':'
				k = k[1..-1]
			else
				v = quote(v)
			end
			keys << '"'+k+'"'
			values << v
		}
		' ('+keys.join(',')+') VALUES ('+values.join(',')+') '
	end
end
$db = Db.init :db=>'deemit',:user=>'general',:pass=>'9Emf3$*',:type=>'pg'
if DEBUG == 1
	$db.debug = true
end
