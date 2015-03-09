module Gremlin
  module Keyboard
    %x{
      for(var k in Phaser.Keyboard){
        if(Phaser.Keyboard.hasOwnProperty(k)){
          if(k === k.toUpperCase()){
            #{const_set("KEY_" + `k`, `Phaser.Keyboard[k]`)}
          }
        }
      }
    }
  end
end
