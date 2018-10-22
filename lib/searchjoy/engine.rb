module Searchjoy
  class Engine < ::Rails::Engine
    isolate_namespace Searchjoy

    initializer "searchjoy" do
      if defined?(Searchkick)
        Searchkick::Query.prepend(Searchjoy::Track)
        Searchkick::Results.send(:attr_accessor, :search)
      end
    end
  end
end
