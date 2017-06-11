class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    if user.has_role? :admin
      can :manage, :all
    else
      user.user_menus.each do |user_menu|
        ability = User::ABILITIES.select{|name, value| value == user_menu.ability}.first.first.downcase.to_sym rescue nil
        class_name = if user_menu.name.eql?("Area Manager")
          "Supervisor"
        elsif user_menu.name.eql?("Stock Balance")
          "Stock"
        elsif user_menu.name.eql?("Cost & Price")
          "CostList"
        elsif user_menu.name.eql?("Receiving")
          "ReceivedPurchaseOrder"
        else
          user_menu.name
        end
        if ability && class_name.eql?("Supervisor")
          can ability, class_name.gsub(/\s+/, "").constantize
          can :get_warehouses, class_name.gsub(/\s+/, "").constantize
        elsif ability
          can ability, class_name.gsub(/\s+/, "").constantize
        end        
      end
    end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end
