ActionController::Routing::Routes.draw do |map|


  map.connect 'trial_tarballs/add_to_experiment', :controller => 'trial_tarballs', :action => 'add_to_experiment'
  map.connect 'trial_tarballs/update_experiment', :controller => 'trial_tarballs', :action => 'update_experiment'
  map.resources :experiments, :collection => {:bozo => :get }

  map.resources :trial_tarballs
  map.resources :func_calls
  map.resources :funcs
  map.resources :library_calls
  map.resources :libraries
  map.resources :raw_paths
  map.resources :module_processing_speeds
  map.resources :program_runs
  map.resources :run_environments
  map.resources :node_loads
  map.resources :event_resource_uses
  map.resources :trials
  map.resources :trial_parameters
  map.resources :trial_parameter_sets
  map.resources :experiments
  map.resources :experiment_parameters
  map.resources :experiment_parameter_sets
  map.resources :build_features
  map.resources :build_feature_sets
  map.resources :parameter_set_names
  map.resources :plot_clusters
  map.resources :path_files
  map.resources :purposes
  map.resources :programs
  map.resources :trial_summary

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
   map.root :controller => "home"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action.:format'
  map.connect ':controller/:action/:id.:format'  
end
