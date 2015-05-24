# Gremlin

Wouldn't it be nice to make web games with a language other than JavaScript?
This is an attempt to get [Opal][] working with [Phaser][] in a fairly
performant manner. Development state: super experimental.

# Usage

```sh
bundle install
bundle exec rake build_example
bundle exec rake serve_example
open http://localhost:8000/
```

## Contributing

1. Fork it ( https://github.com/tomdalling/gremlin/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## TODO

Gremlin:
 - Refactor asset loading so it matches Phaser loading (need to account for
   spritesheets/atlases)
 - Opalize Phaser.Group
 - Opalize Phaser.Tween
 - Opalize Phaser.Geometry?
 - Opal API for mouse input
 - Opal API for touch input
 - Opal API for audio instances.
 - Rethink the API for creating game objects (text, images, sprites, audio, etc).
   Who should be responsible for creation?
 - Investigate whether played sounds need to be `destroy`'d, or if they can just be GC'd
 - Responsive canvas resizing
 - Refactor loading screen

Gemmy:
 - "You win" screen at end
 - "Press any key to begin" on intro
 - Do ENTITY_SORT_ORDER better
 - Try remove NUM_LEVELS and just check text cache instead
 - Rip out custom animation and replace with Phaser animation

[Opal]: http://opalrb.org/
[Phaser]: http://phaser.io/
