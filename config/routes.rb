Rails.application.routes.draw do
  resources :price_lists, except: :show do
    collection do
      get "generate_price_form"
    end
  end
  resources :cost_lists, except: :show
  resources :receiving, only: [:new, :create] do
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
    end    
  end
  resources :stocks, only: :index
  devise_for :users, only: :sessions
  get 'welcome/index'

  resources :purchase_orders do
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
  resources :size_groups
  resources :sales_promotion_girls
  resources :warehouses
  resources :price_codes
  resources :area_managers
  resources :vendors
  resources :regions
  resources :goods_types, except: :show
  resources :models, except: :show
  resources :colors, except: :show
  resources :brands, except: :show
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
