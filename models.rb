require 'datamapper'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3:ichiro.db")
#DataMapper::Model.raise_on_save_failure = true

class Board
	include DataMapper::Resource

	has n, :postthreads, 'PostThread',
		:parent_key => [ :id ],
		:child_key  => [ :board_id ]
	
	property :id,		Serial,		:key => true
	property :name,		String,		:length => 50
	property :dir,		String,		:length => 50
	property :header,	String,		:length => 50
end

class PostThread
	include DataMapper::Resource

	has n, :posts, 'Post',
		:parent_key => [ :id ],
		:child_key  => [ :thread_id ],
		:order => :id.asc
	belongs_to :board, 'Board',
		:parent_key => [ :id ],
		:child_key  => [ :board_id ],
		:required   => true
	
	property :id,			Serial,		:key => true
	property :lastbump,		DateTime
	property :subject,		String,		:length => 50
	property :permasage,	Boolean,	:default => false
	property :sticky,		Boolean,	:default => false
	
	def self.board
		all(:order => :sticky.desc, :order => :lastbump.desc, :limit => settings.threads)
	end
	
	def self.list
		all(:order => :sticky.desc, :order => :lastbump.desc, :limit => settings.threadlinks)
	end
end

class Post
	include DataMapper::Resource

	belongs_to :postthread, 'PostThread',
		:parent_key => [ :id ],
		:child_key  => [ :thread_id ],
		:required   => true
	
	property :id,		Serial
	property :time,		DateTime
	property :ip,		String,		:length => 15
	property :name,		String,		:length => 50
	property :trip,		String,		:length => 10
	property :email,	String,		:length => 50
	property :message,	Text
	property :deleted,	Boolean,	:default => false
end

DataMapper.auto_upgrade!