
#Finds which user is signed in
#Note: The 'exit' method signs out all users each time it is executed 
def which_user
    User.find_by(signed_in?: true)
end

#Determines whether there is a signed-in user
def is_signed_in
    which_user ?
    true : false
end

#Provides different welcome menu templates based on the user's signed-in status
def welcome
    is_signed_in ? welcome2 : welcome1
end

#Provides welcome menu template for user not signed in
def welcome1
    system "clear"
    $prompt.select("Please choose from one of the following options:") do |menu|
        menu.choice "Order", -> { new_order }
        menu.choice "Sign In", -> { sign_in }
        menu.choice "Create Account", -> { create_account }
        menu.choice "Exit", -> { exit_method }
    end
end

#Provides welcome menu template for user signed in
def welcome2
    system "clear"
    $prompt.select("Please choose from one of the following options:") do |menu|
        menu.choice "Order", -> { new_order }
        menu.choice "Account Information", -> { account_method }
        menu.choice "Sign Out", -> { sign_out }
        menu.choice "Exit", -> { exit_method }
    end
end

#Provides different order menu templates based on the user's signed-in status
def new_order
    is_signed_in ? order2 : order1
end

#Provides order menu template for user not signed in
def order1
    $prompt.select("Please choose from one of the following drink options:\n") do |menu|
        system "clear"
        Drink.menu_items.each{|drink_instance| menu.choice name_price_ingredient(drink_instance), -> { order(drink_instance)}}
        menu.choice "Create your own\n", -> { customize }
        menu.choice "Go Back", -> { welcome }
    end 
end

#Provides order menu template for user signed in
#Difference from order1 method is the option to select from saved favorites
def order2
    $prompt.select("Please choose from one of the following drink options:\n") do |menu|
        system "clear"
        Drink.menu_items.each{|drink_instance| menu.choice name_price_ingredient(drink_instance), -> { order(drink_instance)}}
        uniq_favorites.select{|drink_name| Drink.find_by(name: drink_name).is_menu_item? == false}.each{|drink_name| menu.choice name_price_ingredient(Drink.find_by(name: drink_name)), -> { order(Drink.find_by(name: drink_name))}}
        menu.choice "Create your own\n", -> { customize }
        menu.choice "Go Back", -> { welcome }
    end 
end

#Helper method used in order methods that provides the visual template for drink options 
def name_price_ingredient(drink_instance)
    "#{drink_instance.name} | $#{drink_instance.price} | #{(drink_instance.ingredients.map {|ingredient| ingredient.name}).join(", ")}\n"
end

#Allows users to created their own drink
def customize
    new_drink = Drink.create({is_menu_item?: false})
    selection = $prompt.multi_select("Please select ingredients", Ingredient.grouped_by_type.map {|instance| instance.name})
    selection.each {|ingredient_name| RecipeItem.create({drink_id: new_drink.id, ingredient_id: Ingredient.find_by(name: ingredient_name).id})}
    new_drink.update(price: selection.count.to_i)
    order(new_drink)
end 

#Allows user to view drink choice before confirming order
def order(drink_instance)
    system "clear"
    if drink_instance.is_menu_item? == true
        puts "Drink name: #{drink_instance.name}"
    end
    puts "Ingredients: #{(drink_instance.ingredients.map {|ingredient| ingredient.name}).join(", ")}"
    puts "This drink costs $#{drink_instance.price}."
    $prompt.select("Would you like to CONFIRM ORDER or go back?:") do |menu|
        menu.choice "Confirm", -> {order_confirm(drink_instance)}
        menu.choice "Go back", -> {new_order}
    end
end

#Allows user to confirm drink order and displays drink information upon confirmation
#Allows signed-in user to save as favorite
def order_confirm(drink_instance)
    if is_signed_in 
        Order.create({user_id: User.find_by(signed_in?: true).id, drink_id: drink_instance.id, price: drink_instance.price})
        Order.last.favorite(drink_instance)
    else
        Order.create({drink_id: drink_instance.id, price: drink_instance.price})
    end
    system "clear"
    if drink_instance.is_menu_item?
        puts "You have successfully ordered a #{drink_instance.name}. Thanks for coming!"
    else
        puts "You have successfully ordered a customized drink. Thanks for coming!"
    end
    sleep (3)
    welcome
end

#Allows user to sign in
def sign_in
    puts "Please enter username or type 'exit' to exit"
    username = gets.chomp
    if username == "exit"
        welcome
    else
        if user = User.find_by(username: username)
            user.enter_password
        else
            puts "User does not exist"
            sleep (2)
            welcome
        end
    end
end

#Allows user to create an account with username and password
def create_account
    puts "Please enter a username or type 'exit' to return to the main menu:"
    username = gets.chomp
    if username == "exit"
        welcome
    elsif    
        User.find_by(username: username.downcase)
        puts "Username already exists."
        create_account
    else 
        password = $prompt.mask("Please create a password:")
        #Verifies password entry
        if password == $prompt.mask("Please re-enter password:")
            User.create({username: username, password: password, signed_in?: true})
            puts "Account username: \"#{username}\" created! You are now signed in!"
            sleep (2)
            welcome 
        else 
            puts "Passwords did not match, please try again."
            sleep (2)
            create_account
        end
    end 
end

#Provides account menu template only shown to signed-in user 
def account_method
    system "clear"
    $prompt.select("Find the following account options:") do |menu|
        menu.choice "View my Order History", -> {see_orders}
        menu.choice "View my Favorites", -> {see_favorites}
        menu.choice "Delete my Account", -> {delete_account} 
        menu.choice "Go Back", -> {welcome} 
    end
end

#Allows user to view past orders
def see_orders
    system "clear"
    puts "Here is a list of your Orders:"
    which_user.orders.each {|order_instance| puts "~ #{order_instance.drink.name} \n\s\sPrice: $#{order_instance.drink.price} \n\s\sCreated: #{order_instance.created_at.to_s[0,10]}\n\n\t*********\n\n"}
        $prompt.select("Press 'enter' to return to the previous menu.") do |menu|
            menu.choice "", -> {account_method}
        end
end

#Allows user to view saved favorites
def see_favorites
    system "clear"
    puts "Here is a list of your Favorites:"
    uniq_favorites.each {|drink_name| puts "~ #{drink_name} | $#{Drink.find_by(name:drink_name).price} | #{Drink.find_by(name:drink_name).ingredients.map {|ingredient_instance|ingredient_instance.name}.join(", ")}\n"}
        $prompt.select("Press 'enter' to return to the previous menu.") do |menu|
            menu.choice "", -> {account_method}
        end
end

#Helper method that displays an array of unique favorites' names 
def uniq_favorites
    favorites_array = which_user.orders.select {|order_instance| order_instance.favorite? == true}
    favorites_array = favorites_array.map{|favorite| favorite.drink.name}.uniq
end

#Allows user to delete their own account
def delete_account
    system "clear"
    $prompt.select("Would you like to DELETE your account?") do |menu|
        menu.choice "Delete", -> {which_user.orders.destroy_all; which_user.destroy; puts "Your account has been deleted."; sleep(2); welcome}
        menu.choice "Go back", -> {account_method} 
    end
end

#Allows user to sign out of their own account
def sign_out
    $prompt.select("Are you sure that you want to sign out?") do |menu|
        menu.choice "Yes", -> {which_user.update(signed_in?:false);welcome}
        menu.choice "No", -> {welcome}
    end
    
end

#Allows user to exit application
def exit_method
    puts "

Have a Great Day!

 ██████╗  ██████╗  ██████╗ ██████╗ ██████╗ ██╗   ██╗███████╗██╗
 ██╔════╝ ██╔═══██╗██╔═══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝██║
 ██║  ███╗██║   ██║██║   ██║██║  ██║██████╔╝ ╚████╔╝ █████╗  ██║
 ██║   ██║██║   ██║██║   ██║██║  ██║██╔══██╗  ╚██╔╝  ██╔══╝  ╚═╝
 ╚██████╔╝╚██████╔╝╚██████╔╝██████╔╝██████╔╝   ██║   ███████╗██╗
  ╚═════╝  ╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝
    "
    User.all.each {|user_instance| user_instance.update(signed_in?: false)}
    sleep (1.5)
    exit
end