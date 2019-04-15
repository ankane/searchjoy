module Searchjoy
  class Engine < ::Rails::Engine
    isolate_namespace Searchjoy

    initializer "searchjoy" do
      Searchjoy.attach_to_searchkick! if defined?(Searchkick)
    end
  end
end
