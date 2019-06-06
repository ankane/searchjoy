module Searchjoy
  class Engine < ::Rails::Engine
    isolate_namespace Searchjoy

    initializer "searchjoy" do |app|
      # use a proc instead of a string
      app.config.assets.precompile << proc { |path| path == "searchjoy.js" }

      Searchjoy.attach_to_searchkick! if defined?(Searchkick)
    end
  end
end
