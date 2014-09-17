class Post

	attr_reader :id, :message, :date, :author_name, :author_id, :user_name, :user_id

	def initialize(hash)
		@id = hash["id"]
		@message = hash["content"]
		@user_id = hash["user_id"]
		@user_name = hash["user_name"]
		@author_id = hash["author_id"]
		@author_name = hash["name"]
		@date = DateTime.iso8601(hash["date"])
	end

	def pretty_date
		@date.strftime("%B %d, %Y at %l:%M%p") if @date != nil
	end
	
end