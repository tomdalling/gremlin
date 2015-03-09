# Gremlin

Wouldn't it be nice to make web games with a language other than JavaScript?
This is an attempt to get [Opal][] working with [Phaser][] in a fairly
performant manner. Development state: super experimental.

# Usage

```sh
bundle install
bundle exec rake build_game
rake server
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
