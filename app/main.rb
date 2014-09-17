require 'rack'
require 'typhoeus'
require 'json'
require 'ap'
require 'sqlite3'
require 'date'
require 'erubis'
require 'fileutils'
require_relative 'models/user'
require_relative 'models/post'
require_relative 'models/orm'


class App

    def initialize()
        @orm = ORM.new()
        @user_login = nil
        @user_display = nil
        @errors = []
        @user_posts = []
        @news = []
    end

	def call(env)

        request = Rack::Request.new(env)
        response = Rack::Response.new

        case request.path_info
        when '/', "/index" #OK
            @errors = []
            if @user_login
                @user_login.print
                @user_display = @user_login
                get_user_posts
                response.write render("index", {"posts" =>@user_posts})
            else
                response.redirect '/user/connect'
            end

        when '/user/search' #OK
            results = search_users(request)
            response.write render("user/search", {"users" =>results, "user_search" => request.GET['user_search']})

        when '/user/add_friend' #OK revoir html
            add_friend(request)
            response.redirect '/friends'

        when '/post/create' #OK
            create_post(request)
            if @user_display != @user_login
                response.redirect "/user/wall?id=#{@user_display.id}"
            else
                response.redirect '/index'
            end

        when '/friends' #OK
            response.write render('friends')

        when '/user/wall' #OK
            puts request.GET["id"]
            @user_display = @orm.get_user_by_id(request.GET["id"])
            get_user_posts
            response.write render('user/wall', {"friend" =>@user_display, "posts" =>@user_posts})

        when '/news' #OK
            get_all_posts
            response.write render('news', {"posts" =>@user_posts})

        when '/user/connect' #OK
            response.write render('user/connect')

        when '/user/new' #OK
            response.write render "user/new"

        when '/user/create' #OK
            check_create_user_form(request)
            if @errors.empty?
                add_user(request)
                response.redirect '/index'
            else
                response.redirect '/user/new'
            end

        when '/user/login' #OK
            login(request)
            if @errors.empty?
                response.redirect '/index'
            else
                response.redirect '/user/connect'
            end

        when '/user/logout' #OK
            @user_login = nil
            response.redirect '/index'

        when '/user/show'
            response.write render "user/show"

        when '/user/edit'
            response.write render "user/edit"

        when '/user/update'
            check_update_user_form(request)
            if @errors.empty?
                update_user(request)
                response.redirect '/user/show'
            else
                response.redirect '/user/edit'
            end

        when '/external_news'
            response.write render('external_news', {"articles" =>get_external_news})
        end
    
        response.finish

	end

    def check_create_user_form(request)
        ap request.POST
        @errors = []
        ["name", "email", "password"].each do |var|
            @errors << "#{var.capitalize} required" if (request.POST[var] == nil || request.POST[var] == "")
        end
        @errors << "Password confirmation does not match password" if (request.POST['password'] != request.POST['password_confirm'])
        @errors << "Email already exists" if @orm.user_email_exist?request.POST['email']
        @errors << "Name already exists" if @orm.user_name_exist?request.POST['name']
    end

    def check_update_user_form(request)
        ap request.POST
        @errors = []
        ["name", "email"].each do |var|
            @errors << "#{var.capitalize} required" if (request.POST[var] == nil || request.POST[var] == "")
        end
        @errors << "Password confirmation does not match password" if (request.POST['new_password'] != request.POST['new_password_confirm'])
        if request.POST['email'] != @user_login.email
            @errors << "Email already exists" if @orm.user_email_exist?request.POST['email']
        end
        if request.POST['name'] != @user_login.name
            @errors << "Name already exists" if @orm.user_name_exist?request.POST['name']
        end
    end

    def add_user(request)
        @user_login = @orm.create_user(
                                request.POST['name'], 
                                request.POST['email'], 
                                request.POST['password']
                                )
    end

    def update_user(request)
        @user_login.name = request.POST['name']
        @user_login.email = request.POST['email']
        path = request.POST['photo_path']
        if path != nil && File.exist?(path) 
            # TODO Generate a key as the file name intead of using the user id
            # HELP How to get the path of a file?
            # HELP How to use relative path instead of absolute?
            FileUtils.cp(path, "/Users/valentine/Projects/week6 project1/facebook_app/public/images/profil/photo_#{@user_login.id}.jpg")
            @user_login.photo = "photo_#{@user_login.id}.jpg"
        else
            path = "no_photo.jpg"
        end
        @orm.update_user(@user_login)
        if request.POST['new_password'] != nil && request.POST['new_password'] !=""
            @orm.update_password(@user_login, request.POST['new_password'])
        end
    end

    def login(request)
        @errors = []
        if request.POST['email'] == "" or request.POST['password'] == ""
            @errors << "Please enter your e-mail and your password" 
        else
            @user_login = @orm.get_user_login(
                                    request.POST['email'], 
                                    request.POST['password']
                                    )
            if @user_login == nil
                @errors << "Wrong email or pasword"
            else
                @orm.load_friends(@user_login)
            end
        end
    end

    def search_users(request)
        puts "Search: #{request.GET['user_search']}"
        if request.GET['user_search'] != nil && request.GET['user_search'] != ""
            return @orm.find_users(request.GET['user_search'])
        else
            return []
        end
    end

    def create_post(request)
        @orm.create_post(@user_display.id, request.POST['message'], @user_login.id)
    end

    def get_user_posts
        @user_posts = @orm.get_user_posts(@user_display.id)
    end

    def get_all_posts
        @user_posts = @orm.get_news(@user_login)
    end

    def add_friend(request)
        @orm.add_friend(@user_login, request.GET['id'])
    end

    def render(name, locals={})
        locals["errors"] = @errors
        locals["user"] = @user_login
        file = File.read("app/views/"+name+".erb")
        Erubis::Eruby.new(file).result(locals)
    end

    def get_external_news
        result = []
        url = "http://api.feedzilla.com/v1/articles/search.json?count=10"
        response = Typhoeus.get(url)
        data = JSON.parse response.body
        ap data["articles"]
        data["articles"]
    end

end


