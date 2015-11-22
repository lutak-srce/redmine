#ActionController::Routing::Routes.draw do |map|
#  map.resources :public_keys, :controller => 'gitosis_public_keys', :path_prefix => 'my'
#end
RedmineApp::Application.routes.draw do
  resource :public_keys, :controller => 'gitosis_public_keys', :path_prefix => 'my'
end
