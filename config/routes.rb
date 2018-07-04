Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    resources :stock_mutations do
      collection do
        get "store_to_store_inventory_receipts"
        get "search"
      end
      member do
        get "receive"
      end
    end
    resources :consignment_sales do
      collection do
        get "get_events"
        get "get_product"
      end
      member do
        get "approve"
        get "unapprove"
      end
    end
    resources :shipments, except: [:edit, :update] do    
      collection do
        get "inventory_receipts"
        get "search_do"
      end
      member do
        get "receive"
      end
    end
    devise_for :users, only: :sessions
  end

  resources :customers
  resources :consignment_sales do
    collection do
      get "get_product"
      get "get_product_colors"
      get "get_product_sizes"
      get "get_events"
    end
    member do
      get "approve"
      get "unapprove"
    end
  end
  get 'incompatible_browsers/index'

  resources :sales_returns, except: [:edit, :update, :destroy] do
    collection do
      get "search_receipt"
      get "get_replacement_product"
      get "get_replacement_product_colors"
      get "get_replacement_product_sizes"
    end
  end
  #  get 'fake_consignment_sale/sale_entry'
  #  get 'consignments/new' => 'fake_consignment_sale#sale_entry'
  #  get 'fake_consignment_sale/get_product'
  #  get 'consignments' => 'fake_consignment_sale#listing_sale'

  resources :counter_events do    
    collection do
      get "generate_warehouse_form"
      get "add_products"
      get "add_general_products"
    end
    member do
      get "generate_activation_form"
      patch "activate_deactivate"
    end
  end
  resources :companies
  resources :sales, except: [:edit, :update, :destroy] do
    collection do
      get "get_member"
      get "get_product"
      get "get_free_product"
      get "get_product_colors"
      get "get_free_product_colors"
      get "get_product_sizes"
      get "get_free_product_sizes"
      get "get_gift_event_product"
      get "get_gift_event_product_colors"
      get "get_gift_event_product_sizes"
    end
    member do
      get "print"
      get "print_return_receipt"
    end
  end
  resources :members
  resources :banks, except: :show
  resources :cash_disbursements, only: [:index, :new, :create]
  resources :cashier_openings, except: [:edit, :update, :destroy] do
    member do
      get "close"
    end
  end
  resources :events do    
    collection do
      get "generate_warehouse_form"
      get "add_products"
      get "add_general_products"
    end
    member do
      get "generate_activation_form"
      patch "activate_deactivate"
    end
  end
  resources :listing_stocks, only: :index
  resources :stock_movements, only: :index
  resources :fiscal_years
  resources :goods_in_transits, only: [:shipment_goods, :mutation_goods, :returned_goods] do    
    collection do
      get "shipment_goods"
      get "mutation_goods"
      get "returned_goods"
    end
    member do
      get "show_shipment_goods"
      get "show_mutation_goods"
      get "show_returned_goods"
    end
  end

  #  resources :stock_mutation_receipts
  resources :stock_mutations do
    collection do
      get "get_products"
      get "get_saved_products"
      #      get "generate_form"
      get "index_store_to_warehouse_mutation"
      get "show_store_to_warehouse_mutation"
      get "new_store_to_warehouse_mutation"
      get "store_to_store_inventory_receipts"
      get "store_to_warehouse_inventory_receipts"
      post "create_store_to_warehouse_mutation"
      get "search"
    end
    member do
      get "approve"
      #      get "edit_store_to_warehouse"
      get "show_store_to_store_receipt"
      get "show_store_to_warehouse_receipt"
      get "receive"
      get "receive_to_warehouse"
      get "print_rolling_doc"
      get "print_return_doc"
      #      patch "update_store_to_warehouse"
      delete "delete_store_to_warehouse"
      get "change_receive_date"
    end
  end
  #  resources :shipment_receipts, except: [:edit, :update, :destroy] do
  #    collection do
  #      get "generate_form"
  #    end
  #  end
  resources :notifications, only: [:index, :show, :destroy, :notify_user] do 
    collection do
      get "notify_user"
    end
  end
  resources :available_menus, only: [:new, :create]
  resources :shipments, except: [:edit, :update] do    
    collection do
      get "generate_ob_detail"
      get "inventory_receipts"
      get "search_do"
    end
    member do
      get "receive"
      get "change_receive_date"
      get "print"
    end
  end
  resources :couriers, except: :show
  resources :order_bookings do
    collection do
      get "get_warehouse_products"
      get "generate_product_item_form"
    end
    member do
      get "picking_note"
    end
  end
  resources :account_payables, only: [:new, :create, :index, :destroy, :show] do
    collection do
      get 'generate_form'
      get 'generate_dp_payment_form'
      get 'get_purchase_returns'
      get 'get_purchase_returns_for_dp'
      get 'select_purchase_return'
      get 'select_purchase_return_for_dp'
      post 'create_dp_payment'
    end
  end
  resources :emails
  #  resources :price_lists, except: :show do
  #    collection do
  #      get "generate_price_form"
  #    end
  #  end
  #  resources :cost_lists, except: :show
  resources :receiving, only: [:new, :create, :index, :show] do
    collection do
      get "get_product_details"      
    end
    
    member do
      get 'get_purchase_order'
      post 'receive_products_from_purchase_order'
    end
  end

  resources :purchase_returns, except: [:destroy, :edit, :update] do
    collection do
      get 'get_purchase_order_details'
      get 'get_direct_purchase_details'
      post 'create_direct_purchase_return'
      get 'filter_purchase_records'
    end    
    member do
      get 'print'
    end
  end
  resources :stocks, only: :index
  devise_for :users, only: :sessions
  resources :users do
    collection do
      get "generate_spg_user_form"
      get "get_area_manager_info"
    end
  end    
  
  get 'welcome/index'

  resources :purchase_orders do
    collection do
      get 'get_product_details'
    end
    
    member do
      #      get 'receive'
      #      post 'receive'
      get 'close'
      get 'print'
    end
  end
  resources :products do
    collection do
      get 'populate_detail_form'
    end
  end
  resources :size_groups, except: :show
  resources :sales_promotion_girls
  resources :warehouses
  resources :price_codes, except: :show
  resources :area_managers do
    member do
      get "get_warehouses"
    end
  end
  resources :vendors
  resources :regions, except: :show
  resources :goods_types, except: :show
  resources :models, except: :show
  resources :colors, except: :show
  resources :brands, except: :show
  resources :cost_prices do
    get "generate_form", on: :collection
    patch "create", on: :collection
  end
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'
  # Websockets resemble this URL
  mount ActionCable.server => '/cable'

  
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
