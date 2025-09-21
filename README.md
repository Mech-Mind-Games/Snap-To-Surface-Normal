# Snap To Surface Normal

Godot 4.X test project for finding a objects surface normal and aligning player and camera facing direction towards the normal.





**Controls:**

AWSD = move

Left Click = snap position/facing direction (This will only function when the player is actively colliding with the rectangular prism/shelf)

Right Click = unlock the camera snapped rotation

Escape (Esc) = un-hide mouse cursor and unlock mouse from screen lock, only works when player is not snapped

Spacebar = jump (for funsies) 



Feel free to use this for any project.



This is my first project in godot so things might be a little rough, but I tried to provide the logic as best as I possibly could.



I'm sure godot probably has features to simplify the code even more, but this was done in a few spare moments I had.

I'm thinking this could be simplified even more, by instead of needing a raycast, being able to use godot's built in collision detection system to return the surface/surface normal you are colliding with. I just couldn't find the syntax.



I initially tried a more mathematical approach utilizing the prism's (shelfs) overall dimensions, but this led to inconsistent results.

The raycast approach I tested multiple times and did not run into any issues with it. (about 10 minutes of testing at different angles and sides of the prism)



I hope this helps you out on your game dev journey!











