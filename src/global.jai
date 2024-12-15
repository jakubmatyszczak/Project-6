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
        EFFECT;
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

    entities : [1024]Entity;
    nEntities : s32;
    player : s32;
    level : u32;
    levelMax :: 3;
    
    colliders : [1024]Collider;
    collidersActive : s32;

    light : Lights;
}
FrameData :: struct
{
    nEnemies : s32;
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
radToDeg :: (angle: float) -> float
{
    ratio :: 180. / 3.14159;
    return angle * ratio;
}
clamp :: (min: float, max: float, value: float) -> float
{
    if value < min
        return min;
    if value > max
        return max;
    return value;
}
