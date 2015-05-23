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
        normalize_asset_manifest(assets).each do |(type, key, url)|
          `#{self}.load[#{type}](#{key}, #{url})`
        end
      end

      DEFAULT_EXTENSIONS = {
        image: 'png',
        text: 'txt',
        audio: 'wav', #TODO: should this be mp3 or ogg?
      }

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
