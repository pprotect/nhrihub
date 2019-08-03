module UserSetupHelper

  def create_user(login)
    user = User.create(:login => login,
                :email => Faker::Internet.email,
                :enabled => true,
                :firstName => Faker::Name.first_name,
                :lastName => Faker::Name.last_name,
                :organization => Organization.first,
                :public_key => "BMQ+Q7yItYnNYQpzXJm0Eu+esfIDl3PkxQDNK//f0IF1CybZyFYy2VrON8d4riV3hWYzlJQn/hRHw3mWFG9Nj3M=",
                :public_key_handle => "Ym9ndXNfMTQ3MjAxMTYxODU0OA")
    user.update_attribute(:salt, '1641b615ad281759adf85cd5fbf17fcb7a3f7e87')
    user.update_attribute(:activation_code, '9bb0db48971821563788e316b1fdd53dd99bc8ff')
    user.update_attribute(:activated_at, DateTime.new(2011,1,1))
    user.update_attribute(:crypted_password, '660030f1be7289571b0467b9195ff39471c60651')
    create_roles(user, user.login) # in this case, the name of the role is the same as the user's login!
    user
  end

  def create_roles(user, role)
    role = Role.create(:name => role)
    user.roles << role
    user.save
  end

end
