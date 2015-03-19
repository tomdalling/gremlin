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

    def key_down
    end

    private

      def init
        `#{self}.input.keyboard.addCallbacks(#{self}, #{self}['$_handle_key_down'])`
      end

      def _handle_key_down(event)
        key_down(`event.keyCode`)
      end

      def preload
        assets.fetch(:images, {}).each do |key, url|
          `#{self}.load.image(#{key}, #{url})`
        end

        assets.fetch(:text, {}).each do |key, url|
          `#{self}.load.text(#{key}, #{url})`
        end
      end

      def add_sprite(key)
        `#{self}.add.sprite(0, 0, #{key})`
      end

      def add_text(text, style={})
        `#{self}.add.text(0, 0, #{text}, #{style.to_n})`
      end

      # TODO: better name
      def get_text(key)
        `#{self}.cache.getText(#{key})`
      end

      def key_down?(key)
        result = `!!#{self}.input.keyboard.isDown(#{key})`
        result
      end

      def game_size
        Point[`#{self}.game.width`, `#{self}.game.height`]
      end

      def delta_time
        `#{self}.time.physicsElapsed`
      end

      def average_fps
        `#{self}.time.fps`
      end

      def enabled_advanced_timing!
        `#{self}.time.advancedTiming = true`
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
