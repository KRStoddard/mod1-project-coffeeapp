require_relative '../config/environment'

system "clear"

puts "Welcome to K&J Cafe!"

sleep(3)


def welcome
   User.is_signed_in ? welcome2 : welcome1
end

welcome

