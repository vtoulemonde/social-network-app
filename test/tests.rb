require 'minitest/autorun'
require 'sqlite3'
require 'rack'
require 'typhoeus'
require 'json'
require 'date'
require 'erubis'

require_relative '../app/models/orm'
require_relative '../app/models/post'
require_relative '../app/models/user'

class TestSocialDb < MiniTest::Unit::TestCase

    DB_PATH = "test_social.db"

    def setup
        if File.exist? DB_PATH
            File.delete DB_PATH
        end
        @orm = ORM.new(DB_PATH)
        @orm.db.execute_batch File.read('../data/schema.sql')
    end

    def test_create_user()
        result = @orm.create_user("Test", "test@mail.com", "test")
        assert_equal "Test", result.name
    end

end



