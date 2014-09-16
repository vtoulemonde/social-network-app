require 'minitest/autorun'
require 'sqlite3'
require 'rack'
require 'typhoeus'
require 'json'
require 'date'
require 'erubis'

require_relative '../social'

class TestSocialDb < MiniTest::Unit::TestCase

    def setup
        @socialDb = Social::SocialDb.new
    end

    def test_should_exist
        assert_instance_of Class, Social::SocialDb
    end

    def test_create_user()
        result = @socialDb.create_user("Test", "test@mail.com", "test")
        assert_equal "Test", result.name
    end


end



