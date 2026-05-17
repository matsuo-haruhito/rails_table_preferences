# frozen_string_literal: true

module RailsTablePreferences
  class RendererRegistry
    def initialize
      @renderers = {}
    end

    def register(type, renderer = nil, &block)
      callable = renderer || block
      raise ArgumentError, "renderer must respond to call" unless callable.respond_to?(:call)

      @renderers[type.to_s] = callable
    end

    def fetch(type)
      @renderers[type.to_s]
    end

    def registered?(type)
      @renderers.key?(type.to_s)
    end

    def call(type, **context)
      renderer = fetch(type)
      return unless renderer

      if renderer.respond_to?(:arity) && renderer.arity == 1
        renderer.call(context)
      else
        renderer.call(**context)
      end
    end

    def keys
      @renderers.keys
    end
  end
end
