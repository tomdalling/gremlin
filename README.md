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

[Opal]: http://opalrb.org/
[Phaser]: http://phaser.io/

## TODO

 - Refactor asset loading so it matches Phaser loading (need to account for
   spritesheets/atlases)
 - Rip out custom animation from gemmy and replace with Phaser animation
 - Opalize Phaser.Group
 - Opalize Phaser.Tween
 - Remove State class in favour of having a single state for every game
 - Rethink the API for creating game objects (text, images, sprites, audio, etc).
   Who should be responsible for creation?
 - Completely remove naghavi, moving functionality into gremlin
 - Do ENTITY_SORT_ORDER better in gemmy.
 - Opal API for sprite smoothing (global setting?)
 - Try remove NUM_LEVELS from gemmy
 - "You win" screen at end of gemmy
 - "Press any key to begin" on gemmy intro
 - Investigate whether played sounds need to be `destroy`'d, or if they can just be GC'd
 - Opal API for audio instances.
 - Responsive canvas resizing
 - Refactor loading screen
 - API for mouse input
 - API for touch input
