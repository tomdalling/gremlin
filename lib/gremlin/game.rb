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
    def key_down; end
    #TODO: key_up, touch_down, touch_up, etc.

    # override to return an asset manifest
    def assets
      raise NotImplementedError
    end

    def add_sprite(key)
      `#{self}.add.sprite(0, 0, #{key})`
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

      def phaser_init
        `#{self}.input.keyboard.addCallbacks(#{self}, #{self}['$_handle_key_down'])`
        init
      end

      def phaser_preload
        normalize_asset_manifest(assets).each do |(type, key, url)|
          `#{self}.load[#{type}](#{key}, #{url})`
        end
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

      def patch_phaser_methods!
        PATCHED_METHODS.each do |opal_key, js_key|
          `#{self}[#{js_key}] = #{self}["$" + #{opal_key}]`
        end
      end

      # [type, key, url]
      def normalize_asset_manifest(assets_by_type)
        assets_by_type.flat_map do |type, asset_list|
          asset_list.flat_map do |asset|
            key, count, ext = normalize_asset(asset)
            ext ||= DEFAULT_EXTENSIONS[type]

            if count
              count.times.map do |idx|
                num = (idx+1).to_s.rjust(2, '0')
                [type, key+idx.to_s, "asset/#{type}/#{key}_#{num}.#{ext}"]
              end
            else
              [[type, key, "asset/#{type}/#{key}.#{ext}"]]
            end
          end
        end
      end

      # [key, count, ext]
      def normalize_asset(asset)
        if asset.is_a? String
          [asset, nil, nil]
        else
          case asset.size
          when 1 then [asset.first, nil, nil]
          when 2
            if asset.last.is_a? Integer
              [asset.first, asset.last, nil]
            else
              [asset.first, nil, asset.last]
            end
          when 3 then asset
          else fail("Invalid asset: #{item.inspect}") unless (1..3).include?(item.size)
          end
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

      DEFAULT_EXTENSIONS = {
        image: 'png',
        text: 'txt',
        audio: 'wav', #TODO: should this be mp3/ogg?
      }
  end
end
