# TODO

- PROBLEM!!!: enemy lands on Hector and is stuck (Fixed 2/28 a few hours later oops)
- Name tile maps like BlahTileMap
  - we may need to check if the collision object is TileMap
- sliding animation (partly done 2/24/24)
- interfaces/inheritance
- Death blocks? (got a few 2/24/24)
- add some momentum, when we stop inputing a direction he should slide a bit more in the (this is pretty good as of 2/24/24, even better 2/27 it now is almost as config as jumping)
  last direction especially if running
- running should have more ramp up time (time to full speed) (I still think this 2/24/24 (3/30 this is pretty good see momentum comment a few up))
- falling platforms need to regen
- Duck, jump and attack animation leaves player in running-ish state, this is a bug or we need a better attack animation/default post attack state

NOT TODO:
- Fixed all pixel snags in tile set (fixed by moving the collision boxes)
- we need to differentiate between sliding down a slope and sliding off a ledge (corner) this should not be considered sliding (we don't slide if not on 45 degree slope, a ledge is 180 and so outside of our +45 and -45 degree tolerance)
   -use RayCast2D to determine when we are on a ledge (see BounceBaddie.gd)
- Sync sounds with belt animation being done not beginning (this is pretty good now)

# Things we have decided
 - attack = down for upward momentum, left still gives left momentum, right gives right, and up gives downward momentum


CLEANUP TODO: (4/28/24)
- make everything its own method


## Features we need for test gounds
- Debug menu for putting items, moving player, setting settings 
- enemy spawn button (an "item" you touch to spawn specific enemy)
