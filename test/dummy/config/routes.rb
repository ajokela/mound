Rails.application.routes.draw do

  mount Mound::Engine => '/rabl'
end
