class User

	attr_reader :id
	attr_accessor :friends, :name, :email, :photo, :description

	def initialize(hash)
		@id = hash["id"]
		@name = hash["name"]
		@email = hash["email"]
		# @password = hash["password"]
		@friends = []
		@photo = hash["photo"]
		@description = hash["description"]
	end

	def print
		puts "#{@id}, #{@name}, #{@email}"
	end

end