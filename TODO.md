# TODO

- PROBLEM!!!: enemy lands on Hector and is stuck (Fixed 2/28 a few hours later oops)
- duck animation makes Hector a few pixels off ground (Should be fixed)
- Name tile maps like BlahTileMap
  - we may need to check if the collision object is TileMap
- sliding animation (partly done 2/24/24)
- interfaces/inheritance
- Death blocks? (got a few 2/24/24)
- add some momentum, when we stop inputing a direction he should slide a bit more in the (this is pretty good as of 2/24/24, even better 2/27 it now is almost as config as jumping)
  last direction especially if running
- Add low jump and high jump dependent on how long pressed
- running should have more ramp up time (time to full speed) (I still think this 2/24/24 (3/30 this is pretty good see momentum comment a few up))
- Sync sounds with belt animation being done not beginning
- TODO: we need to differentiate between sliding down a slope and sliding off a ledge (corner) this should not be considered sliding
   -use RayCast2D to determine when we are on a ledge (see BounceBaddie.gd)

NOT TODO:
- Fixed all pixel snags in tile set

# Things we have decided
 - attack = down for upward momentum, left still gives left momentum, right gives right, and up gives downward momentum
