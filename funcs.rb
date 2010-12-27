require 'digest/md5'

def sanitizestr (inputstr)
	return inputstr.strip.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
end

def threadsummary (thread)
	output = []
	posts = thread.posts.all(:order => :id.desc).all(:limit => settings.replies)
	posts.each do |post|
		output << post
	end
	output << thread.posts.first
	output.reverse
end

def formatstr (inputstr)
	if inputstr =~ /^&lt;pre&gt;/ && inputstr =~ /&lt;\/pre&gt;$/ then
		inputstr.gsub!(/&lt;pre&gt;(.+?)&lt;\/pre&gt;/im, "<span class=\"aa\">\\1</span>")
	else
		allowedtags = ["b", "i", "u", "s", "sub", "sup"]
		allowedtags.each do |tag|
			inputstr.gsub!(/&lt;#{tag}&gt;(.+?)&lt;\/#{tag}&gt;/im, "<#{tag}>\\1</#{tag}>")
		end
		inputstr.gsub!("\n", "<br>\n")
	end
	inputstr
end

def readmodifier (modifier, posts)
	originalposts = posts
	matches = modifier.match(/^([0-9]+)n?$/) # Single POST
	if !matches.nil? then
		posts = [ posts.first(:relid => matches[1]) ]
	else
		matches = modifier.match(/^([0-9]+)n?\-$/) # POST and every post after
		if !matches.nil? then
			if modifier =~ /n/ then
				posts = posts.all(:relid.gte => matches[1])
			else
				posts = posts.all(:relid => 1) + posts.all(:relid.gte => matches[1])
			end
		else
			matches = modifier.match(/^\-([0-9]+)n?$/) # Every post up to and including POST
			if !matches.nil? then
				posts = posts.all(:relid.lte => matches[1])
			else
				matches = modifier.match(/^([0-9]+)n?\-([0-9]+)n?$/) # Every post from POST to POST
				if !matches.nil? then
					if modifier =~ /n/ then
						posts = posts.all(:relid.gte => matches[1]) & posts.all(:relid.lte => matches[2])
					else
						posts = posts.all(:relid => 1) + posts.all(:relid.gte => matches[1]) & posts.all(:relid.lte => matches[2])
					end
				else
					matches = modifier.match(/^l([0-9]+)n?$/) # Last (num) posts
					if !matches.nil? then
						if modifier =~ /n/ then
							posts = posts.all(:relid.gt => (posts.count - matches[1].to_i))
						else
							posts = posts.all(:relid => 1) + posts.all(:relid.gt => (posts.count - matches[1].to_i))
						end
					end
				end
			end
		end
	end
	if posts == [ nil ] then
		posts = originalposts
	end
	posts
end

def displayerror (message)
	@error = message
	erb :error
end

def displaymessage (message)
	@message = message
	erb :message
end
