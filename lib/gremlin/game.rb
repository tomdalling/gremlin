module Gremlin
  class Game < `Phaser.State`
    # lifecycle callbacks
    def init; end
    def create; end
    def update; end
    def render; end
    def paused; end
    def pause_update; end
    def resize; end
    def shutdown; end

    # event callbacks
    def key_down(key); end
    def key_up(key); end
    def pointer_down(pointer); end
    def pointer_up(pointer); end

    # override to return an asset manifest
    def assets
      raise NotImplementedError
    end

    def add_sprite(key)
      s = `#{self}.add.sprite(0, 0, #{key})`
      `#{s}.smoothed = #{@smooth_sprites}`
      s
    end

    def add_text(text, style={})
      `#{self}.add.text(0, 0, #{text}, #{style.to_n})`
    end

    def play_sound(key, looping=false)
      s = `#{self}.sound.add(#{key})`
      `#{s}.loop = #{looping}`
      `#{s}.play()`
      s
    end

    # TODO: better name
    def get_text(key)
      `#{self}.cache.getText(#{key})`
    end

    def key_down?(key)
      `!!#{self}.input.keyboard.isDown(#{key})`
    end

    def pointer_down?
      `#{self}.input.mousePointer`.down? || `#{self}.input.pointers`.any?(&:down?)
    end

    def canvas_size
      Vec2[`#{self}.game.width`, `#{self}.game.height`]
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

    protected
      attr_accessor :smooth_sprites

      def phaser_init
        %x{
          #{self}.input.keyboard.addCallbacks(
            #{self},
            #{self}['$_handle_key_down'],
            #{self}['$_handle_key_up']
          )

          #{self}.input.onDown.add(#{self}['$_handle_pointer_down'], #{self})
          #{self}.input.onUp.add(#{self}['$_handle_pointer_up'], #{self})
        }
        init
      end

      def phaser_preload
        pack = Gremlin::AssetPack.from_manifest(assets)
        `#{self}.load.pack("assets", null, #{pack})`
      end

      def phaser_load_update
        return if `#{self}.state._created`

        unless @_loading_text
          @_loading_text = add_text("Loading...", fill: 'white')
          @_loading_text.position.eset!(15, 15)
          @_loading_bar = `#{self}.add.graphics(0,0)`
          `#{@_loading_bar}.beginFill(0xFFFFFF, 1)`
          `#{@_loading_bar}.drawRect(0, 0, 1, 10)`
          `#{@_loading_bar}.endFill()`
        end

        progress = `#{self}.load.progress / 100`
        @_loading_bar.scale.eset!(progress * `#{self}.game.width`, 1)
      end

      def phaser_create
        @_loading_text.destroy! if @_loading_text
        @_loading_bar.destroy! if @_loading_bar
        create
      end

      def phaser_render; render; end
      def phaser_update; update; end
      def phaser_paused; paused; end
      def phaser_pause_update; pause_update; end
      def phaser_resize; resize; end
      def phaser_shutdown; shutdown; end

    private

      def _handle_key_down(event)
        key_down(`#{event}.keyCode`)
      end

      def _handle_key_up(event)
        key_up(`#{event}.keyCode`)
      end

      def _handle_pointer_down(pointer, event)
        pointer_down(pointer)
      end

      def _handle_pointer_up(pointer, event)
        # phaser doesn't set `pointerUp` until AFTER the `onUp` signal has fired.
        # no idea why, but this is a fix:
        pointer.position_up.set!(pointer.position)

        pointer_up(pointer)
      end

      def patch_phaser_methods!
        PATCHED_METHODS.each do |opal_key, js_key|
          `#{self}[#{js_key}] = #{self}["$" + #{opal_key}]`
        end
      end

      PATCHED_METHODS = {
        phaser_init: 'init',
        phaser_preload: 'preload',
        phaser_load_render: 'loadRender',
        phaser_load_update: 'loadUpdate',
        phaser_create: 'create',
        phaser_update: 'update',
        phaser_render: 'render',
        phaser_paused: 'paused',
        phaser_pause_update: 'pauseUpdate',
        phaser_resize: 'resize',
        phaser_shutdown: 'shutdown'
      }
  end
end
