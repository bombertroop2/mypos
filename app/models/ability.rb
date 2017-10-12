class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    if user.has_role? :superadmin
      can :manage, :all
    elsif user.has_role? :administrator
      (User::MENUS.clone << "User").each do |user_menu|
        if user_menu.eql?("User") || AvailableMenu.select("1 AS one").where(active: true, name: user_menu).present?
          class_name = if user_menu.eql?("Area Manager")
            "Supervisor"
          elsif user_menu.eql?("Stock Balance")
            "Stock"
          elsif user_menu.eql?("Cost & Price")
            "CostList"
          elsif user_menu.eql?("Receiving")
            "ReceivedPurchaseOrder"
          elsif user_menu.eql?("Fiscal Reopening/Closing")
            "FiscalYear"
          elsif user_menu.eql?("Listing Stocks")
            "ListingStock"
          else
            user_menu
          end
          if class_name.eql?("Goods In Transit")
            can :manage, Shipment
            can :manage, StockMutation
          else
            can :manage, class_name.gsub(/\s+/, "").constantize
          end
        end
      end
      can :manage, Notification
    elsif user.roles.first.present? && SalesPromotionGirl::ROLES.select{|a, b| b.eql?(user.roles.first.name)}.present?
      user.user_menus.each do |user_menu|
        if user_menu.ability != 0 && AvailableMenu.select("1 AS one").where(active: true, name: user_menu.name).present? && !user_menu.name.eql?("Account Payable") && !user_menu.name.eql?("Fiscal Reopening/Closing")
          ability = User::ABILITIES.select{|name, value| value == user_menu.ability}.first.first.downcase.to_sym rescue nil
          class_name = if user_menu.name.eql?("Area Manager")
            "Supervisor"
          elsif user_menu.name.eql?("Stock Balance")
            "Stock"
          elsif user_menu.name.eql?("Cost & Price")
            "CostList"
          elsif user_menu.name.eql?("Receiving")
            "ReceivedPurchaseOrder"
          elsif user_menu.name.eql?("Listing Stocks")
            "ListingStock"
          else
            user_menu.name
          end
          if class_name.eql?("Supervisor")
            can :read, class_name.gsub(/\s+/, "").constantize
            can :get_warehouses, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("Shipment")
            # cegah non manager keatas untuk menghapus shipment
            alias_action :index, :inventory_receipts, :show, to: :read_action
            can [:read_action, :receive], class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("Stock Mutation")
            if ability.eql?(:read)
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :store_to_store_inventory_receipts, :show_store_to_store_receipt, to: :read_store_to_store_inventory_receipts
              can [:read_store_to_store_mutations, :read_store_to_warehouse_mutations, :read_store_to_store_inventory_receipts], class_name.gsub(/\s+/, "").constantize
            else
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :new_store_to_warehouse_mutation,
                :create_store_to_warehouse_mutation, :generate_form, :edit_store_to_warehouse,
                :update_store_to_warehouse, :delete_store_to_warehouse, :get_products, to: :manage_store_to_warehouse_mutation
              alias_action :store_to_store_inventory_receipts, :show_store_to_store_receipt, to: :read_store_to_store_inventory_receipts
              can [:read_store_to_store_mutations, :read_store_to_warehouse_mutations, :manage_store_to_warehouse_mutation, :approve, :receive, :read_store_to_store_inventory_receipts], class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("Goods In Transit")
            alias_action :shipment_goods, :show_shipment_goods, to: :read_shipment_goods
            alias_action :mutation_goods, :returned_goods, :show_mutation_goods, :show_returned_goods, to: :read_mutation_goods
            can :read_shipment_goods, Shipment
            can :read_mutation_goods, StockMutation
          else
            can :read, class_name.gsub(/\s+/, "").constantize
          end        
        end        
      end
      can :manage, Notification
    else
      user.user_menus.each do |user_menu|
        if user_menu.ability != 0 && AvailableMenu.select("1 AS one").where(active: true, name: user_menu.name).present?
          ability = User::ABILITIES.select{|name, value| value == user_menu.ability}.first.first.downcase.to_sym rescue nil
          class_name = if user_menu.name.eql?("Area Manager")
            "Supervisor"
          elsif user_menu.name.eql?("Stock Balance")
            "Stock"
          elsif user_menu.name.eql?("Cost & Price")
            "CostList"
          elsif user_menu.name.eql?("Receiving")
            "ReceivedPurchaseOrder"
          elsif user_menu.name.eql?("Fiscal Reopening/Closing")
            "FiscalYear"
          elsif user_menu.name.eql?("Listing Stocks")
            "ListingStock"
          else
            user_menu.name
          end
          if ability && class_name.eql?("Supervisor")
            unless user.has_role?(:accountant)
              can ability, class_name.gsub(/\s+/, "").constantize
              can :get_warehouses, class_name.gsub(/\s+/, "").constantize
            else
              can :read, class_name.gsub(/\s+/, "").constantize
              can :get_warehouses, class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("Shipment")
            # cegah non manager keatas untuk menghapus shipment
            alias_action :new, :create, :generate_ob_detail, to: :undelete_action
            alias_action :index, :inventory_receipts, :show, to: :read_action
            alias_action :edit, :update, :destroy, to: :edit_action
            if ability.eql?(:manage) && user.roles.first.name.eql?("staff")
              can [:read_action, :undelete_action], class_name.gsub(/\s+/, "").constantize
            elsif user.roles.first.name.eql?("staff") || user.has_role?(:accountant)
              can :read_action, class_name.gsub(/\s+/, "").constantize
            elsif ability.eql?(:read) && user.roles.first.name.eql?("manager")
              can :read_action, class_name.gsub(/\s+/, "").constantize
            elsif user.roles.first.name.eql?("manager")
              can [:read_action, :undelete_action, :edit_action], class_name.gsub(/\s+/, "").constantize
            end
          elsif (class_name.eql?("Product") || class_name.eql?("Purchase Order")) && !user.has_managerial_role?
            # cegah staff untuk manage product
            can :read, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("CostList") && !user.has_managerial_role?
            # cegah staff untuk manage Cost dan Price
            can :read, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("Stock Mutation")
            if ability.eql?(:read) || user.has_role?(:accountant)
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :store_to_store_inventory_receipts, :show_store_to_store_receipt, to: :read_store_to_store_inventory_receipts
              alias_action :store_to_warehouse_inventory_receipts, :show_store_to_warehouse_receipt, to: :read_store_to_warehouse_inventory_receipts
              can [:read_store_to_store_mutations, :read_store_to_warehouse_mutations, :read_store_to_store_inventory_receipts, :read_store_to_warehouse_inventory_receipts], class_name.gsub(/\s+/, "").constantize
            else
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :new, :create, :get_products, :generate_form, :edit, :update, :destroy, to: :manage_store_to_store_mutation
              alias_action :store_to_store_inventory_receipts, :show_store_to_store_receipt, to: :read_store_to_store_inventory_receipts
              alias_action :store_to_warehouse_inventory_receipts, :show_store_to_warehouse_receipt, to: :read_store_to_warehouse_inventory_receipts
              can [:read_store_to_store_mutations, :manage_store_to_store_mutation, :read_store_to_warehouse_mutations, :read_store_to_store_inventory_receipts, :read_store_to_warehouse_inventory_receipts, :receive_to_warehouse], class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("Goods In Transit")
            alias_action :shipment_goods, :show_shipment_goods, to: :read_shipment_goods
            alias_action :mutation_goods, :returned_goods, :show_mutation_goods, :show_returned_goods, to: :read_mutation_goods
            can :read_shipment_goods, Shipment
            can :read_mutation_goods, StockMutation
          elsif class_name.eql?("Account Payable") && user.has_role?(:staff)
            can :read, AccountPayable
          elsif class_name.eql?("Account Payable")
            can ability, AccountPayable
          elsif class_name.eql?("FiscalYear")
            if user.has_role?(:staff)
              can :read, FiscalYear
            else
              can ability, FiscalYear
            end
          elsif ability && !user.has_role?(:accountant)
            can ability, class_name.gsub(/\s+/, "").constantize
          elsif ability && user.has_role?(:accountant)
            can :read, class_name.gsub(/\s+/, "").constantize
          end        
        end        
      end
      can :manage, Notification unless user.new_record?
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
