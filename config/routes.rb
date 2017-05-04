Rails.application.routes.draw do
  resources :order_bookings do
    collection do
      get "get_warehouse_products"
      get "generate_product_item_form"
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
    end    
  end
  resources :stocks, only: :index
  devise_for :users, only: :sessions
  get 'welcome/index'

  resources :purchase_orders, except: [:edit, :update] do
    collection do
      get 'get_product_details'
    end
    
    member do
      #      get 'receive'
      #      post 'receive'
      get 'close'
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
