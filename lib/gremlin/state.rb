module Gremlin
  class State < `Phaser.State`
    def initialize
      PATCHED_METHODS.each do |opal_key, js_key|
        `#{self}[#{js_key}] = #{self}["$" + #{opal_key}]`
      end
    end

    def assets
      {}
    end

    private

      def preload
        assets.fetch(:images, {}).each do |key, url|
          `#{@load}.image(#{key}, #{url})`
        end
      end

      def add_sprite(key)
        `#{@add}.sprite(0, 0, #{key})`
      end

      def add_text(text, style={})
        `#{@add}.text(0, 0, #{text}, #{style.to_n})`
      end

      def key_down?(key)
        result = `!!#{@input}.keyboard.isDown(#{key})`
        result
      end

      def game_size
        Point[`#{@game}.width`, `#{@game}.height`]
      end

      def delta_time
        `#{@time}.physicsElapsed`
      end

      def average_fps
        `#{@time}.fps`
      end

      def enabled_advanced_timing!
        `#{@time}.advancedTiming = true`
      end

      PATCHED_METHODS = {
        init: 'init',
        preload: 'preload',
        load_render: 'loadRender',
        load_update: 'loadUpdate',
        create: 'create',
        update: 'update',
        render: 'render',
        paused: 'paused',
        pause_update: 'pauseUpdate',
        resize: 'resize',
        shutdown: 'shutdown',
      }
  end
end
