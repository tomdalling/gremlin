require 'opal'
require 'native'
require 'gremlin/version'
require 'gremlin/vec2'
require 'gremlin/display_object'
require 'gremlin/keyboard'
require 'gremlin/state'
require 'gremlin/game'
require 'gremlin/sprite'
require 'gremlin/text'
require 'gremlin/graphics'

module Gremlin

  def self.lerp(from, to, fraction)
    case
    when fraction <= 0.0 then from
    when fraction >= 1.0 then to
    else from + fraction*(to - from)
    end
  end

end
