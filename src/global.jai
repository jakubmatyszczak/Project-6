#load "light.jai";

Entity :: struct
{
    Arch :: enum
    {
        UNKNOWN;
        PLAYER;
        ITEM;
        OBJECT;
        PROJECTILE;
        ENEMY;
    };
    active : bool;
    arch : Arch;

    pTexture : TexId;
    dpos : Vector2;
    rot : float;
    scale : float;
    color : rl.Color;

    fpos : Vector2;
    fvel : Vector2;
    data : [1024]u8;
}
Globals :: struct
{
    content : Content;
    camera : rl.Camera2D;
    screenSize : Vector2;
    mouseScreen : Vector2;
    mouseWorld : Vector2;
    time : float;

    entities : [128]Entity;
    player : s32;
    level : u32;
    levelMax :: 3;
    
    colliders : [128]Collider;
    collidersActive : s32;

    light : Lights;
}
FrameData :: struct
{
    targetTile : Vector2;
}

frame := FrameData.{};
g := Globals.{};

polarToXY :: (angle: float, radius : float) -> Vector2
{
    xy : Vector2 = ---;
    xy.x = sin(angle) * radius;
    xy.y = cos(angle) * radius;
    return xy;
}
