#load "animation.jai";
TexId :: enum u32
{
    NONE :: 0;
    HEX :: 1;
    ORB :: 2;
    ROCK :: 3;
    KNIFE :: 4;
    PLAYER :: 5;
}
Content :: struct
{
    textures : [8]rl.Texture2D;
}
content_init :: (c : *Content)
{
    c.textures[TexId.HEX] = rl.LoadTexture("res/hex.png");
    c.textures[TexId.ORB] = rl.LoadTexture("res/orb.png");
    c.textures[TexId.ROCK] = rl.LoadTexture("res/rock.png");
    c.textures[TexId.KNIFE] = rl.LoadTexture("res/knife.png");
    c.textures[TexId.PLAYER] = rl.LoadTexture("res/player.png");
}

Item :: struct
{
    Arch :: enum
    {
        UNKNOWN;
        KNIFE;
        ROPE;
    };
    pEntity : s32;

    arch : Arch;
    isPicked : bool;
    isThrown : bool;
    isTied : bool;

    canStrike : bool;
    canThrow : bool;
    canTie : bool;
    
    throwVel : Vector2;
    nBonded : u32;
    bonded : [2]s32; // pEntity
}
Player :: struct
{
    pEntity: s32;

    angle : float;
    aim : Vector2;

    hover : Animation;
    jump : Animation;
    pLight : s32;
}
Object :: struct
{
    Arch :: enum
    {
        UNKNOWN;
        ROCK;
        ;
    };
    pEntity : s32;

    arch : Arch;
    shake : Animation;
}
Projectile :: struct
{
    pEntity : s32;
    target : Vector2;
    spawn : Vector2;
}

entity_create :: (arch: Entity.Arch, fpos: Vector2, pTexture: TexId) -> s32
{
    for *entity : g.entities
    {
        if entity.active
            continue;
        entity.active = true;
        entity.arch = arch;
        entity.fpos = fpos;
        entity.pTexture = pTexture;
        entity.scale = 1;
        memset(entity.data.data, 0, entity.data.count);
        return cast(s32)it_index;
    }
    return -1;
}
entity_destroy :: (pEntity: s32)
{
    if pEntity > 0 && pEntity < 128
        g.entities[pEntity].active = false;
}
entities_process :: ()
{
    using Entity;
    for * entity : g.entities
    {
        if !entity.active
            continue;
        if entity.arch == 
        {
            case Arch.UNKNOWN;
            case Arch.PLAYER;
                // player_process(xx it_index);
            case Arch.ITEM;
                item_process(xx it_index);
            case Arch.OBJECT;
                object_process(xx it_index);
            case Arch.PROJECTILE;
                // projectile_draw(xx it_index);
        }
    }
}
entities_update :: (dt: float)
{
    using Entity;
    for * entity : g.entities
    {
        if !entity.active
            continue;
        if entity.arch == 
        {
            case Arch.UNKNOWN;
            case Arch.PLAYER;
                player_update(xx it_index, dt);
            case Arch.ITEM;
                item_update(xx it_index, dt);
            case Arch.OBJECT;
                object_update(xx it_index, dt);
            case Arch.PROJECTILE;
                projectile_update(xx it_index, dt);
        }
    }
}
entities_draw :: ()
{
    using Entity;
    for * entity : g.entities
    {
        if !entity.active
            continue;
        if entity.arch == 
        {
            case Arch.UNKNOWN;
            case Arch.PLAYER;
                player_draw(xx it_index);
            case Arch.ITEM;
                item_draw(xx it_index);
            case Arch.OBJECT;
                object_draw(xx it_index);
            case Arch.PROJECTILE;
                projectile_draw(xx it_index);
        }
    }
}
getEntityFromPEntity :: (pEntity: s32) -> *Entity
{
    return *g.entities[pEntity];
}
getPlayerFromPEntity :: (pEntity: s32) -> *Player, *Entity
{
    return cast(*Player)g.entities[pEntity].data.data, *g.entities[pEntity];
}
getItemFromPEntity :: (pEntity: s32) -> *Item, *Entity
{
    return cast(*Item)g.entities[pEntity].data.data, *g.entities[pEntity];
}
getObjectFromPEntity :: (pEntity: s32) -> *Object, *Entity
{
    return cast(*Object)g.entities[pEntity].data.data, *g.entities[pEntity];
}
getProjectileFromPEntity :: (pEntity: s32) -> *Projectile, *Entity
{
    return cast(*Projectile)g.entities[pEntity].data.data, *g.entities[pEntity];
}

projectile_create :: (fpos : Vector2, target : Vector2) -> s32
{
    pEntity := entity_create(Entity.Arch.PROJECTILE, fpos, TexId.NONE);
    proj, e := getProjectileFromPEntity(pEntity);
    proj.target = target;
    proj.spawn = fpos;
    e.fvel = normalize(target - fpos) * 20;
    return pEntity;
}
projectile_update :: (pEntity: s32, dt: float)
{
    proj, ent := getProjectileFromPEntity(pEntity);
    ent.fpos += ent.fvel;
    ent.fvel *= 0.96;
    if (length(ent.fvel) < 1)
        entity_destroy(pEntity);
}
projectile_draw :: (pEntity: s32)
{
    proj, ent := getProjectileFromPEntity(pEntity);
    rl.DrawLineEx(ent.fpos, normalize(ent.fpos - proj.spawn) * 80, 4, rl.BLUE);
    rl.DrawCircleV(ent.fpos, 12, rl.BLUE);
}
object_create_rock :: (fpos : Vector2)
{ 
    pEntity := entity_create(Entity.Arch.OBJECT, fpos, TexId.ROCK);
    e : *Entity = *g.entities[pEntity];
    e.scale = 4;
    e.color = xx rl.DARKGRAY;
    
    rock : *Object = xx e.data.data;
    rock.pEntity = pEntity;
    rock.arch = Object.Arch.ROCK;
    rock.shake = anim_create_shake(10);
}
object_process:: (pEntity: s32)
{
    obj, ent := getObjectFromPEntity(pEntity);
}
object_update :: (pEntity: s32, dt: float)
{
    obj, ent := getObjectFromPEntity(pEntity);
    anim_update(*obj.shake, dt);
}
object_draw :: (pEntitiy: s32)
{
    obj, ent := getObjectFromPEntity(pEntitiy);
    e : *Entity = *g.entities[obj.pEntity];
    e.dpos = e.fpos + anim_getPos(obj.shake);
    src : rl.Rectangle;
    if obj.arch ==
    {
        case Object.Arch.ROCK;
            src = .{0, 0, 16, 16};
    }
    rl.DrawTexturePro(g.content.textures[e.pTexture],
        src,
        .{e.dpos.x, e.dpos.y, src.width * e.scale, src.height * e.scale},
        .{src.width / 2 * e.scale, src.height / 2 * e.scale},
        0.,
        rl.WHITE);
}

player_create :: (pos : Vector2) -> s32
{
    pEntity := entity_create(Entity.Arch.PLAYER, pos, TexId.PLAYER);
    e : *Entity = *g.entities[pEntity];
    e.scale = 3;
    e.color = xx rl.GREEN;
    
    p : *Player = xx e.data.data;
    p.hover = anim_create_hover(2, 16);
    p.jump = anim_create_jump(-64);
    anim_start(*p.hover);
    p.pLight = light_create(pos, 250, 0.7);
    light_enable(p.pLight, true);
    return pEntity;
}
player_input :: (pEntity: s32, up : bool, down : bool, left : bool, right : bool,
                interact: bool, shoot: bool)
{
    p, e := getPlayerFromPEntity(pEntity);
    p.aim = e.fpos + normalize(g.mouseWorld - e.fpos) * g.screenSize.y * 0.25;

    moveDir : Vector2;
    if up moveDir.y -= 1;
    if down moveDir.y += 1;
    if right moveDir.x += 1;
    if left moveDir.x -= 1;
    e.fvel += normalize(moveDir) * 2;
    e.fvel *= 0.8;
    e.fpos += e.fvel;
    if interact
        projectile_create(e.fpos, g.mouseWorld);
}
player_update :: (pEntity: s32, dt : float)
{
    p, e := getPlayerFromPEntity(pEntity);
    anim_update(*p.hover, dt);
    anim_update(*p.jump, dt);
}
player_draw :: (pEntity: s32)
{
    p, e := getPlayerFromPEntity(pEntity);
    e.dpos = e.fpos;
    light_getById(p.pLight).fpos = (e.dpos + p.aim) * 0.5;
    sine := cos(g.time * 3.14159);    
    rl.DrawEllipse(xx e.fpos.x, xx e.fpos.y, 12+sine, 8+sine, .{50,50,50,200});
    rl.DrawTexturePro(g.content.textures[e.pTexture],
        .{0,0,32,64},
        .{e.dpos.x, e.dpos.y, 32, 64},
        .{16, 32},
        0, rl.RED);
}
hud_draw :: ()
{
    player, playerEntity := getPlayerFromPEntity(g.player);
}
item_create_knife :: (pos : Vector2)
{
    pEntity := entity_create(Entity.Arch.ITEM, pos, TexId.KNIFE);
    entity : *Entity = *g.entities[pEntity];
    item : *Item = cast(*Item)entity.data.data;

    entity.scale = 3;

    item.arch = Item.Arch.KNIFE;
    item.canStrike = true;
    item.canThrow = true;
}
item_pickup :: (pEntity: s32)
{
    item, entity := getItemFromPEntity(pEntity);
    item.isPicked = true;
    item.isThrown = false;
    item.throwVel = .{};
}
item_process:: (pEntity: s32)
{
    item, entity := getItemFromPEntity(pEntity);
}
item_update :: (pEntity: s32, dt : float)
{
    item, entity := getItemFromPEntity(pEntity);
}
item_draw :: (pEntitiy: s32, dpos : Vector2, rotation: float = 0., drawSpecial: bool = false)
{
    item, entity := getItemFromPEntity(pEntitiy);
    src : rl.Rectangle;
    if item.arch ==
    {
        case item.Arch.KNIFE;
            src = .{0, 0, 16, 8};
    }
    if !item.isPicked
    {
        if !item.isThrown
            rotation = 45;
        sine := sin(g.time*4);    
        rl.DrawEllipse(cast(s32)entity.fpos.x, cast(s32)entity.fpos.y,
                        src.width+sine, src.height+sine, .{50,50,50,200});
    }
    rl.DrawTexturePro(g.content.textures[entity.pTexture],
        src,
        .{dpos.x, dpos.y, src.width * entity.scale, src.height * entity.scale},
        .{src.width / 2 * entity.scale, src.height / 2 * entity.scale},
        rotation,
        rl.WHITE);
}
item_draw :: (pEntitiy: s32, calledByPicker: bool = false, drawSpecial: bool = false)
{
    item, entity := getItemFromPEntity(pEntitiy);
    if !item.isPicked || calledByPicker || item.isThrown
        item_draw(pEntitiy, entity.dpos, entity.rot, drawSpecial=drawSpecial);
}

