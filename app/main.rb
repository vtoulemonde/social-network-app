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
    end

	def call(env)

        request = Rack::Request.new(env)
        response = Rack::Response.new
        user_login = nil
        
        paths_with_login = ['/', '/index', '/user/search', '/friends', '/user/add_friend', '/post/create', '/user/wall', '/news', '/user/show', '/user/edit', '/user/update', '/external_news']
        if paths_with_login.include?(request.path_info) && request.session['user_id'] == nil
            response.redirect '/user/connect'
            return response.finish
        end

        user_login = @orm.get_user_by_id(request.session['user_id']) if request.session['user_id']

        case request.path_info
        when '/', "/index"
            posts = @orm.get_user_posts(user_login.id)
            response.write render("index", {"user"=> user_login, "posts" => posts})

        when '/user/search'
            results = search_users(request)
            response.write render("user/search", {"user"=> user_login, "users" =>results, "user_search" => request.GET['user_search']})

        when '/friends'
            @orm.load_friends(user_login)
            response.write render('friends', {"user"=> user_login})

        when '/user/add_friend'
            @orm.add_friend(user_login, request.GET['id'])
            response.redirect '/friends'

        when '/post/create'
            wall_id = request.POST['wall_id']
            if wall_id
                @orm.create_post(wall_id, request.POST['message'], user_login.id)
                response.redirect "/user/wall?id=#{wall_id}"
            else
                @orm.create_post(user_login.id, request.POST['message'], user_login.id)
                response.redirect '/index'
            end

        when '/user/wall'
            user_wall = @orm.get_user_by_id(request.GET["id"])
            response.write render('user/wall', {"user"=> user_login, "friend" =>user_wall, "posts" =>@orm.get_user_posts(user_wall.id)})

        when '/news'
            response.write render('news', {"user"=> user_login, "posts" =>@orm.get_all_posts(user_login)})

        when '/user/connect'
            response.write render('user/connect', {"errors"=>[]})

        when '/user/login'
            errors = login(request, response)
            if errors.empty?
                response.redirect '/index'
            else
                response.write render('user/connect', {"errors"=>errors})
            end

        when '/user/new'
            response.write render "user/new", {"errors"=> []}

        when '/user/create'
            errors = check_create_user_form(request)
            if errors.empty?
                user = @orm.create_user(request.POST['name'], request.POST['email'], request.POST['password'])
                response.session['user_id'] = user.id
                response.redirect '/index'
            else
                response.write render('/user/new', {"errors" =>errors})
            end

        when '/user/logout'
            request.session['user_id'] = nil
            response.redirect '/index'

        when '/user/show'
            response.write render "user/show", {"user"=> user_login}

        when '/user/edit'
            response.write render "user/edit", {"user"=> user_login, "errors"=> errors}

        when '/user/update'
            errors = check_update_user_form(request, user_login)
            if errors.empty?
                update_user(request, user_login)
                response.redirect '/user/show'
            else
                response.write render("user/edit", {"user"=> user_login, "errors"=> errors})
            end

        when '/external_news'
            response.write render('external_news', {"user"=> user_login,"articles" =>get_external_news})
        end
    
        response.finish

	end

    def check_create_user_form(request)
        errors = []
        ["name", "email", "password"].each do |var|
            errors << "#{var.capitalize} required" if (request.POST[var] == nil || request.POST[var] == "")
        end
        errors << "Password confirmation does not match password" if (request.POST['password'] != request.POST['password_confirm'])
        errors << "Email already exists" if @orm.user_email_exist?request.POST['email']
        errors << "Name already exists" if @orm.user_name_exist?request.POST['name']
        errors
    end

    def check_update_user_form(request, user_login)
        errors = []
        ["name", "email"].each do |var|
            errors << "#{var.capitalize} required" if (request.POST[var] == nil || request.POST[var] == "")
        end
        errors << "Password confirmation does not match password" if (request.POST['new_password'] != request.POST['new_password_confirm'])
        errors << "Email already exists" if (request.POST['email'] != user_login.email && @orm.user_email_exist?(request.POST['email']))
        errors << "Name already exists" if (request.POST['name'] != user_login.name && @orm.user_name_exist?(request.POST['name']))
        errors
    end

    def update_user(request, user_login)
        user_login.name = request.POST['name']
        user_login.email = request.POST['email']

        # TODO Generate a key as the file name intead of using the user id
        if request.POST["photo"]
            user_login.photo = "photo_#{user_login.id}.jpg"
            File.open("public/images/profil/#{user_login.photo}", 'w+') do |file|
                file.write(request.POST["photo"][:tempfile].read)
            end
        end
        @orm.update_user(user_login)
        if request.POST['new_password'] != nil && request.POST['new_password'] !=""
            @orm.update_password(user_login, request.POST['new_password'])
        end
    end

    def login(request, response)
        errors = []
        if request.POST['email'] == "" or request.POST['password'] == ""
            errors << "Please enter your e-mail and your password" 
        else
            user = @orm.get_user_login(request.POST['email'], request.POST['password'])
            if user == nil
                errors << "Wrong email or pasword"
            else
                request.session['user_id'] = user.id
            end
        end
        errors
    end

    def search_users(request)
        if request.GET['user_search'] == 'all'
            return @orm.find_all_users
        elsif request.GET['user_search'] != nil && request.GET['user_search'] != ""
            return @orm.find_users(request.GET['user_search'])
        else
            return []
        end
    end

    def render(name, locals={})
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


