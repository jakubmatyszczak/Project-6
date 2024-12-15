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
    Type :: enum
    {
        LINEAR;
        MAGIC;
    }
    Stage :: enum
    {
        CREATE;
        SHOOT;
        DESTROY;
    }
    pEntity : s32;
    target : Vector2;
    spawn : Vector2;
    range : float;
    type : Type;

    pLight : s32;
    stage: Stage;
    timer: float;

    pCollider : s32;
    colliderGroup : Collider.Group;
}
Enemy :: struct 
{
    Type :: enum
    {
        BASIC;
    }
    pEntity : s32;
    rangeMax : float;
    rangeOptimal : float;
    speed : float;
    timer : float;
    
    pCollider : s32;
}
Collider :: struct
{
    Group :: enum
    {
        HITS_PLAYER;
        HITS_ENEMY;
    }
    pCollider : s32;

    fpos : Vector2;
    radius : float;
    group : Group;
    isHitter : bool;
    
    processed : bool;   // was processed this frame?
    collided : bool;    // is colliding with other nonHitter
    hit : bool;         // was hit by Hitter collider?
    collisionVector: Vector2; // only valid if collided
}

collider_add :: (fpos : Vector2, radius : float, group : Collider.Group, isHitter: bool) -> s32
{
    pCollider : s32 = g.collidersActive;
    g.colliders[pCollider] = .{pCollider = pCollider, fpos = fpos, radius = radius, group = group,
                                hit = false, processed = false, collided = false, isHitter = isHitter};
    g.collidersActive += 1;
    return pCollider;
}
collider_process :: ()
{
    for a : 0..g.collidersActive-1
        for b : 0..g.collidersActive-1 
        {
            if a == b
                continue;
            colliderA : *Collider = *g.colliders[a];
            colliderB : *Collider = *g.colliders[b];
            colliderA.processed = true;
            colliderB.processed = true;
            if colliderA.group != colliderB.group
                continue;
            if length(colliderA.fpos - colliderB.fpos) > (colliderA.radius + colliderB.radius)
                continue; // no intersection
            if !colliderA.isHitter && !colliderB.isHitter
            {
                colliderA.collided = true;
                colliderB.collided = true;
                colliderA.collisionVector += normalize(colliderB.fpos - colliderA.fpos);
                colliderB.collisionVector += -colliderA.collisionVector;
            }
            else
            {
                colliderA.hit = true;
                colliderB.hit = true;
            }
        }
}
collider_finish :: ()
{
    for *collider : g.colliders
    {
        collider.processed = false;
        collider.collisionVector = .{};
    }
    g.collidersActive = 0;
}
collider_isHit :: (pCollider: s32) -> bool
{
    collider := getColliderFromPCollider(pCollider);
    return (collider.processed && collider.hit);
}
collider_isCollided :: (pCollider: s32) -> bool, Vector2
{
    collider := getColliderFromPCollider(pCollider);
    return (collider.processed && collider.collided), collider.collisionVector;
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
        g.nEntities += 1;
        return cast(s32)it_index;
    }
    return -1;
}
entity_destroy :: (pEntity: s32)
{
    if pEntity > 0 && pEntity < 1024
    {
        g.entities[pEntity].active = false;
        g.nEntities -= 1;
    }
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
                projectile_process(xx it_index);
            case Arch.ENEMY;
                enemy_process(xx it_index);
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
            case Arch.ENEMY;
                enemy_update(xx it_index, dt);
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
            case Arch.ENEMY;
                enemy_draw(xx it_index);
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
getEnemyFromPEntity :: (pEntity: s32) -> *Enemy, *Entity
{
    return cast(*Enemy)g.entities[pEntity].data.data, *g.entities[pEntity];
}
getColliderFromPCollider :: (pCollider: s32) -> *Collider
{
    return *g.colliders[pCollider];
}

enemy_create :: (fpos : Vector2, type: Enemy.Type) -> s32
{
    pEntity := entity_create(Entity.Arch.ENEMY, fpos, TexId.ORB);
    enemy, ent := getEnemyFromPEntity(pEntity);
    enemy.rangeMax = 500;
    enemy.rangeOptimal = 300;
    enemy.speed = 2;
    return pEntity;
}
enemy_process:: (pEntity: s32)
{
    enemy, ent := getEnemyFromPEntity(pEntity);
    enemy.pCollider = collider_add(ent.fpos, 30, Collider.Group.HITS_ENEMY, false);
}
enemy_update :: (pEntity: s32, dt: float)
{
    enemy, ent := getEnemyFromPEntity(pEntity);
    player, entPlayer := getPlayerFromPEntity(g.player);
    if (collider_isHit(enemy.pCollider))
    {
        entity_destroy(pEntity);
        return;
    }

    toPlayer := entPlayer.fpos - ent.fpos;
    toPlayerLen := length(toPlayer);

    enemy.timer += dt;
    if  toPlayerLen > enemy.rangeOptimal
        ent.fvel = normalize(toPlayer) * enemy.speed; 
    else
        ent.fvel = .{0, 0};

    isCollided, vector := collider_isCollided(enemy.pCollider);
    if isCollided
        ent.fvel -= vector * 0.5; // 0.5 makes it smoother, less jumpy

    if toPlayerLen < enemy.rangeMax && enemy.timer > 1.3
    {
        enemy.timer = 0;
        projectile_create(ent.fpos, entPlayer.fpos, Projectile.Type.LINEAR, enemy.rangeMax, 
            Collider.Group.HITS_PLAYER);
    }    
    ent.fpos += ent.fvel;
}
enemy_draw :: (pEntity: s32)
{
    enemy, ent := getEnemyFromPEntity(pEntity);
    rl.DrawCircleV(ent.fpos, 30, rl.RED); 
}
projectile_create :: (fpos : Vector2, targetx : Vector2, typex: Projectile.Type,
                        range: float = 500, colliderGroup: Collider.Group) -> s32
{
    pEntity := entity_create(Entity.Arch.PROJECTILE, fpos, TexId.NONE);
    proj, e := getProjectileFromPEntity(pEntity);
    proj.target = targetx;
    proj.spawn = fpos;
    proj.type = typex;
    proj.colliderGroup = colliderGroup;
    if proj.type == {
        case Projectile.Type.LINEAR;
        {
            proj.pLight = light_create(e.fpos, 50, 0.7, rl.WHITE);
            light_enable(proj.pLight, true);
            e.fvel = normalize(targetx - fpos) * 4;
            proj.range = range;
        }
        case Projectile.Type.MAGIC;
        {
            proj.stage = Projectile.Stage.CREATE;
            proj.pLight = light_create(e.fpos, 50, 0.7, rl.BLUE);
            light_enable(proj.pLight, true);
            e.fvel = normalize(targetx - fpos);
            proj.range = range;
        }
    }
    return pEntity;
}
projectile_process:: (pEntityx: s32)
{
    proj, ent := getProjectileFromPEntity(pEntityx);
    proj.pCollider = collider_add(ent.fpos, 6, proj.colliderGroup, true);
}
projectile_update :: (pEntityx: s32, dt: float)
{
    shouldDelete := false;
    proj, ent := getProjectileFromPEntity(pEntityx);
    collider := getColliderFromPCollider(proj.pCollider);
    if (collider_isHit(proj.pCollider))
        shouldDelete = true;
    if proj.type == {
        case Projectile.Type.LINEAR;
        {
            ent.fvel *= 0.999;
            if length(ent.fpos - proj.spawn) > proj.range
                shouldDelete = true;
        }
        case Projectile.Type.MAGIC;
        {
            proj.timer += dt;
            if proj.timer > 0.25
                proj.stage = Projectile.Stage.SHOOT;
            if proj.timer > 1.5 || length(ent.fpos - proj.spawn) > proj.range
                proj.stage = Projectile.Stage.DESTROY;
            if proj.stage == 
            {
                case Projectile.Stage.SHOOT;
                    ent.fvel *= 1.1;
                case Projectile.Stage.DESTROY;
                {
                    ent.fvel *= 0.7;
                    if length(ent.fvel) < 1
                        shouldDelete = true;
                }
            }
        }
    }
    ent.fpos += ent.fvel;
    light_getById(proj.pLight).fpos = ent.fpos;
    if (shouldDelete)
    {
        light_delete(proj.pLight);
        entity_destroy(pEntityx);
    }
}
projectile_draw :: (pEntity: s32)
{
    proj, ent := getProjectileFromPEntity(pEntity);
    clr := rl.BLUE;
    if proj.type == Projectile.Type.LINEAR
        clr = rl.RED;
    else
        rl.DrawLineEx(ent.fpos, proj.spawn, 3, clr);
    rl.DrawCircleV(ent.fpos, 12, clr);
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
    p.pLight = light_create(pos, 450, 0.7, 0.75);
    light_enable(p.pLight, true);
    return pEntity;
}
player_input :: (pEntity: s32, up : bool, down : bool, left : bool, right : bool,
                interact: bool, shoot: bool)
{
    p, e := getPlayerFromPEntity(pEntity);
    p.aim = e.fpos + normalize(g.mouseWorld - e.fpos) * g.screenSize.y * 0.05;

    moveDir : Vector2;
    if up moveDir.y -= 1;
    if down moveDir.y += 1;
    if right moveDir.x += 1;
    if left moveDir.x -= 1;
    e.fvel += normalize(moveDir) * 1.25;
    e.fvel *= 0.8;
    e.fpos += e.fvel;
    if interact
        projectile_create(e.fpos, g.mouseWorld, Projectile.Type.MAGIC, 500, Collider.Group.HITS_ENEMY);
}
player_update :: (pEntity: s32, dt : float)
{
    p, e := getPlayerFromPEntity(pEntity);
    l := light_getById(p.pLight);
    l.fpos = e.fpos;
    l.direction = atan2(-(g.mouseWorld - e.fpos).y, (g.mouseWorld - e.fpos).x) - 1.579;
    anim_update(*p.hover, dt);
    anim_update(*p.jump, dt);
}
player_draw :: (pEntity: s32)
{
    p, e := getPlayerFromPEntity(pEntity);
    e.dpos = e.fpos;
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

