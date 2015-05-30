module Gremlin
  class AssetPack

    def initialize(asset_manifest)
      @animations = {}
      @assets = asset_manifest.flat_map do |type, asset_list|
        asset_list.map do |asset|
          key, options = Array(asset)
          hash = { key: key, type: IRREGULAR_TYPES.fetch(type, type) }
          hash.merge!(send("#{type}_options", key, options || {}))
          @animations[key] = hash.delete(:_animations) if hash[:_animations]
          hash
        end
      end
    end

    def phaser_pack_object
      {
        assets: @assets,
        meta: {
          generated: `Date.now()`,
          version: '1.0',
          app: 'Gremlin',
          url: 'https://github.com/tomdalling/gremlin',
        },
      }.to_n
    end

    def animations
      @animations
    end

    def image_options(key, opts)
      {
        url: "asset/image/#{opts.fetch(:path, key + '.png')}",
        overwrite: opts.fetch(:overwrite, false),
      }
    end

    def text_options(key, opts)
      {
        url: "asset/text/#{opts.fetch(:path, key + '.txt')}",
        overwrite: opts.fetch(:overwrite, false),
      }
    end

    def json_options(key, opts)
      {
        url: "asset/json/#{opts.fetch(:path, key + '.json')}",
        overwrite: opts.fetch(:overwrite, false),
      }
    end

    def script_options(key, opts)
      {
        url: "asset/script/#{opts.fetch(:path, key + '.js')}",
      }
    end

    def binary_options(key, opts)
      {
        url: "asset/binary/#{opts.fetch(:path, key + '.bin')}",
      }
    end

    def spritesheet_options(key, opts)
      {
        url: "asset/spritesheet/#{opts.fetch(:path, key + '.png')}",
        frameWidth: opts.fetch(:frame_size)[0],
        frameHeight: opts.fetch(:frame_size)[1],
        frameMax: opts.fetch(:frame_max, -1),
        margin: opts.fetch(:margin, 0),
        spacing: opts.fetch(:spacing, 0),
      }
    end

    def audio_options(key, opts)
      paths = Array(opts[:path] || opts[:paths] || key + '.mp3')
      {
        urls: paths.map{ |p| "asset/audio/#{p}" },
        autoDecode: opts.fetch(:auto_decode, true),
      }
    end

    def tilemap_options(key, opts)
      {
        url: "asset/tilemap/#{opts.fetch(:path, key + '.csv')}",
        data: opts.fetch(:data, nil),
        format: opts.fetch(:format, 'CSV'),
      }
    end

    def physics_options(key, opts)
      {
        url: "asset/physics/#{opts.fetch(:path, key + '.json')}",
        data: opts.fetch(:data, nil),
        format: opts.fetch(:format, 'LIME_CORONA_JSON'),
      }
    end

    def bitmap_font_options(key, opts)
      raise NotImplementedError, 'Bitmap fonts are not implemented yet'
    end

    def atlas_options(key, opts)
      {
        atlasURL: "asset/atlas/#{opts.fetch(:data_path, key + '.json')}",
        textureURL: "asset/atlas/#{opts.fetch(:texture_path, key + '.png')}",
        atlasData: opts.fetch(:data, nil),
        format: opts.fetch(:format, 'TEXTURE_ATLAS_JSON_ARRAY'),
        _animations: opts.fetch(:animations, [ANIM_DEFAULTS]).map{ |a| ANIM_DEFAULTS.merge(a) },
      }
    end

    IRREGULAR_TYPES = {
      bitmap_font: 'bitmapFont',
    }

    ANIM_DEFAULTS = {
      name: :default,
      frames: nil,
      fps: 5,
      loop: true,
    }

  end
end
