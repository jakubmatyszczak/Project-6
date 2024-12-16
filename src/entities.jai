TexId :: enum u32
{
    NONE :: 0;
    HEX :: 1;
    PLAYER :: 5;
    EXPLOSION;
    EXPLOSION_LINE;
}
SfxId :: enum u32
{
    NONE :: 0;
    JUMP :: 1;
    HIT :: 2;
    ATTACK_QUICK;
    ATTACK_LONG;
    ALARM;
    BOOM;
}
Content :: struct
{
    textures : [8]rl.Texture2D;
    sfx : [8]rl.Sound;
}
content_init :: (c : *Content)
{
    c.textures[TexId.HEX] = rl.LoadTexture("res/hex.png");
    c.textures[TexId.PLAYER] = rl.LoadTexture("res/player.png");
    c.textures[TexId.EXPLOSION] = rl.LoadTexture("res/explosion.png");
    c.textures[TexId.EXPLOSION_LINE] = rl.LoadTexture("res/explosion_line.png");
    c.sfx[SfxId.JUMP] = rl.LoadSound("res/sfx/jump.wav");
    c.sfx[SfxId.HIT] = rl.LoadSound("res/sfx/hit.wav");
    c.sfx[SfxId.ATTACK_QUICK] = rl.LoadSound("res/sfx/attackQuick.wav");
    c.sfx[SfxId.ATTACK_LONG] = rl.LoadSound("res/sfx/attackLong.wav");
    c.sfx[SfxId.ALARM] = rl.LoadSound("res/sfx/alarm.wav");
    c.sfx[SfxId.BOOM] = rl.LoadSound("res/sfx/boom.wav");
}
sound_play :: (id: SfxId, volume: float, pitch: float)
{
    sound := g.content.sfx[id];
    rl.SetSoundVolume(sound, volume);
    rl.SetSoundPitch(sound, pitch); 
    rl.PlaySound(sound);
}

Player :: struct
{
    pEntity: s32;

    ded : bool;
    angle : float;
    aim : Vector2;
    hp : float;

    pLight : s32;
    pCollider : s32;
    pEffectDeath : s32;
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
        RINGO;
    }
    pEntity : s32;
    type : Type;

    rangeMax : float;
    rangeOptimal : float;
    speed : float;
    cooldown : float;
    size : float;

    timer : float;
    pCollider : s32;
    pColliderAux : s32;
}
Effect :: struct
{
    Type :: enum
    {
        EXPLOSION;
        EXPLOSION_LINE;
    }
    pEntity : s32;
    pLight : s32;
    
    timer : float;

    frame : s32;
    frames : s32;
    frameSize : Vector2;
    timePerFrame : float;
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
    isCollider : bool;
    
    processed : bool;   // was processed this frame?
    collided : bool;    // is colliding with other nonHitter
    hit : bool;         // was hit by Hitter collider?
    collisionVector: Vector2; // only valid if collided
}

collider_add :: (fpos : Vector2, radius : float, group : Collider.Group,
                    isHitter: bool, isCollider: bool) -> s32
{
    pCollider : s32 = g.collidersActive;
    g.colliders[pCollider] = .{pCollider = pCollider, fpos = fpos, radius = radius, group = group,
                                hit = false, processed = false, collided = false,
                                isHitter = isHitter, isCollider = isCollider};
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
            if colliderA.isHitter && colliderB.isHitter
                continue; // both hitters - ignore collision
            if length(colliderA.fpos - colliderB.fpos) > (colliderA.radius + colliderB.radius)
                continue; // no intersection
            if colliderA.isCollider && colliderB.isCollider
            {
                colliderA.collided = true;
                colliderB.collided = true;
                colliderA.collisionVector += normalize(colliderB.fpos - colliderA.fpos);
                colliderB.collisionVector += -colliderA.collisionVector;
            }
            if colliderA.isHitter || colliderB.isHitter
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
        memset(entity, 0, size_of(Entity));
        entity.active = true;
        entity.arch = arch;
        entity.fpos = fpos;
        entity.pTexture = pTexture;
        entity.scale = 1;
        entity.color = rl.WHITE;
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
                player_process(xx it_index);
            case Arch.PROJECTILE;
                projectile_process(xx it_index);
            case Arch.ENEMY;
                frame.nEnemies+=1;
                enemy_process(xx it_index);
            case Arch.EFFECT;
                // effect_process(xx it_index);
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
            case Arch.PROJECTILE;
                projectile_update(xx it_index, dt);
            case Arch.ENEMY;
                enemy_update(xx it_index, dt);
            case Arch.EFFECT;
                effect_update(xx it_index, dt);
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
            case Arch.PROJECTILE;
                projectile_draw(xx it_index);
            case Arch.ENEMY;
                enemy_draw(xx it_index);
            case Arch.EFFECT;
                effect_draw(xx it_index);
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
getProjectileFromPEntity :: (pEntity: s32) -> *Projectile, *Entity
{
    return cast(*Projectile)g.entities[pEntity].data.data, *g.entities[pEntity];
}
getEnemyFromPEntity :: (pEntity: s32) -> *Enemy, *Entity
{
    return cast(*Enemy)g.entities[pEntity].data.data, *g.entities[pEntity];
}
getEffectFromPEntity :: (pEntity: s32) -> *Effect, *Entity
{
    return cast(*Effect)g.entities[pEntity].data.data, *g.entities[pEntity];
}
getColliderFromPCollider :: (pCollider: s32) -> *Collider
{
    return *g.colliders[pCollider];
}

// relativeRadius is apperant size, for example for a 32x32 box it will be 16-22.6 (a/2, or d/2)
effect_create :: (fpos : Vector2, type: Effect.Type, relativeRadius: float, color: rl.Color) -> s32
{
    texture : TexId;
    if type == 
    {
    case Effect.Type.EXPLOSION;
        texture = TexId.EXPLOSION;
    case Effect.Type.EXPLOSION_LINE;
        texture = TexId.EXPLOSION_LINE;
    }
    pEntity := entity_create(Entity.Arch.EFFECT, fpos, texture);
    effect, ent := getEffectFromPEntity(pEntity);
    {
        using effect;
        type = type;
        ent.color = color;
        if type == 
        { 
            case Type.EXPLOSION;
                frame = 0;
                frames = 6;
                frameSize = .{32, 32};
                timePerFrame = 0.08;
                ent.scale = relativeRadius / 8;
                pLight = light_create(ent.fpos, relativeRadius*4, 1., rl.ORANGE);
                light_enable(pLight, true);
            case Type.EXPLOSION_LINE;
                frame = 0;
                frames = 6;
                frameSize = .{16, 16};
                timePerFrame = 0.06;
                ent.scale = relativeRadius / 8;
                pLight = light_create(ent.fpos, relativeRadius*4, 0.5, rl.PURPLE);
                light_enable(pLight, true);
        }
    }
    return pEntity;
}
effect_update :: (pEntityx : s32, dt: float)
{
    effect, ent := getEffectFromPEntity(pEntityx);
    {
        using effect;
        timer += dt;
        ent.fpos += ent.fvel;
        ent.fvel *= 0.8;
        if pLight
            light_update(pLight, ent.fpos);
        if timer < timePerFrame 
            return;
        timer = 0.;
        frame += 1;
        if frame > frames
        {
            if pLight
                light_delete(pLight);
            entity_destroy(pEntityx);
            return;
        }
    }
}
effect_draw :: (pEntityx : s32)
{
    effect, ent := getEffectFromPEntity(pEntityx);
    {
        using effect;
        srcRect : rl.Rectangle = .{frame * frameSize.x, 0, frameSize.x, frameSize.y};
        dstRect : rl.Rectangle = .{ent.fpos.x, ent.fpos.y, ent.scale * frameSize.x, ent.scale * frameSize.y};
        rl.DrawTexturePro(g.content.textures[ent.pTexture], srcRect, dstRect, frameSize*ent.scale/2,
                            radToDeg(ent.rot) , ent.color);
    }
}
effect_setValue :: (pEntityx : s32, velocity : Vector2, rotation: float)
{
    effect, ent := getEffectFromPEntity(pEntityx);
    ent.fvel = velocity;
    ent.rot = rotation;
}

enemy_create :: (fpos : Vector2, type: Enemy.Type) -> s32
{
    pEntity := entity_create(Entity.Arch.ENEMY, fpos, TexId.NONE);
    enemy, ent := getEnemyFromPEntity(pEntity);
    enemy.type = type;
    if type ==
    {
    case Enemy.Type.BASIC;
       enemy.rangeMax = 500;
       enemy.rangeOptimal = 300;
       enemy.speed = 2;
       enemy.cooldown = 1.3;
       enemy.size = 30;
    case Enemy.Type.RINGO;
       enemy.rangeMax = 600;
       enemy.rangeOptimal = 400;
       enemy.speed = 1;
       enemy.cooldown = 2.1;
       enemy.size = 50;
    }
    return pEntity;
}
enemy_process:: (pEntity: s32)
{
    enemy, ent := getEnemyFromPEntity(pEntity);
    if enemy.type ==
    {
    case Enemy.Type.BASIC;
        enemy.pCollider = collider_add(ent.fpos, enemy.size, Collider.Group.HITS_ENEMY, false, true);
    case Enemy.Type.RINGO;
        auxPos := polarToXY(g.time, enemy.size-16/4);
        enemy.pCollider = collider_add(ent.fpos, enemy.size, Collider.Group.HITS_ENEMY, false, true);
        enemy.pColliderAux = collider_add(ent.fpos + auxPos, 16, Collider.Group.HITS_ENEMY, false, false);
    }
}
enemy_update :: (pEntity: s32, dt: float)
{
    enemy, ent := getEnemyFromPEntity(pEntity);
    player, entPlayer := getPlayerFromPEntity(g.player);

    toPlayer := entPlayer.fpos - ent.fpos;
    toPlayerLen := length(toPlayer);
    
    if enemy.type ==
    {
    case Enemy.Type.BASIC;
        if (collider_isHit(enemy.pCollider))
        {
            effect_create(ent.fpos, Effect.Type.EXPLOSION, enemy.size, rl.RED);
            entity_destroy(pEntity);
            sound_play(SfxId.BOOM, 1.5, 1.4);
            return;
        }
    case Enemy.Type.RINGO;
        if (collider_isHit(enemy.pColliderAux))
        {
            effect_create(ent.fpos, Effect.Type.EXPLOSION, enemy.size, rl.RED);
            entity_destroy(pEntity);
            sound_play(SfxId.BOOM, 1.8, 1.);
            return;
        }
    }

    if  toPlayerLen > enemy.rangeOptimal
        ent.fvel = normalize(toPlayer) * enemy.speed; 
    else
        ent.fvel = .{0, 0};

    isCollided, vector := collider_isCollided(enemy.pCollider);
    if isCollided
        ent.fvel -= vector * 0.5; // 0.5 makes it smoother, less jumpy

    enemy.timer += dt;
    if toPlayerLen < enemy.rangeMax && enemy.timer > enemy.cooldown
    {
        enemy.timer = 0;
        if enemy.type ==
        {
        case Enemy.Type.BASIC;
            projectile_create(ent.fpos, entPlayer.fpos, Projectile.Type.LINEAR, enemy.rangeMax, 
                Collider.Group.HITS_PLAYER);
            sound_play(SfxId.ATTACK_QUICK, 1., random_get_within_range(0.4, 0.5));
        case Enemy.Type.RINGO;
            sound_play(SfxId.ATTACK_LONG, 1., random_get_within_range(0.4, 0.5));
            for i : 0..5
            {
                dir := polarToXY(xx i, 10);
                projectile_create(ent.fpos + dir, ent.fpos + dir * 2, Projectile.Type.LINEAR, 
                    enemy.rangeMax, Collider.Group.HITS_PLAYER);
            }
        }
    }    
    ent.fpos += ent.fvel;
}
enemy_draw :: (pEntity: s32)
{
    enemy, ent := getEnemyFromPEntity(pEntity);
    if enemy.type ==
    {
    case Enemy.Type.BASIC;
        rl.DrawCircleV(ent.fpos, enemy.size, rl.RED); 
    case Enemy.Type.RINGO;
        rl.DrawCircleV(ent.fpos, enemy.size, rl.RED); 
        rl.DrawCircleV(ent.fpos, enemy.size * sin(g.time)* 0.5 + 1, rl.BLACK); 
        collider := getColliderFromPCollider(enemy.pColliderAux);
        rl.DrawCircleV(collider.fpos, collider.radius, rl.YELLOW); 
    }
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
    proj.pCollider = collider_add(ent.fpos, 6, proj.colliderGroup, true, false);
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
        pEffect := effect_create(ent.fpos, Effect.Type.EXPLOSION_LINE, 16, rl.BLUE);
        effect_setValue(pEffect, ent.fvel, atan2(ent.fvel.y, ent.fvel.x));
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

player_create :: (pos : Vector2) -> s32
{
    pEntity := entity_create(Entity.Arch.PLAYER, pos, TexId.PLAYER);
    e : *Entity = *g.entities[pEntity];
    e.scale = 3;
    e.color = xx rl.GREEN;
    
    p : *Player = xx e.data.data;
    p.hp = 100;
    p.pLight = light_create(pos, 450, 1., 0.75);
    return pEntity;
}
player_input :: (pEntity: s32, up : bool, down : bool, left : bool, right : bool,
                interact: bool, shoot: bool)
{
    p, e := getPlayerFromPEntity(pEntity);
    if p.ded
        return;
    p.aim = e.fpos + normalize(g.mouseWorld - e.fpos) * g.screenSize.y * 0.05;

    moveDir : Vector2;
    if up moveDir.y -= 1;
    if down moveDir.y += 1;
    if right moveDir.x += 1;
    if left moveDir.x -= 1;
    e.fvel += normalize(moveDir) * 1.25;
    e.fvel *= 0.8;
    if shoot 
    {
        projectile_create(e.fpos, g.mouseWorld, Projectile.Type.MAGIC, 500, Collider.Group.HITS_ENEMY);
        sound_play(SfxId.ATTACK_QUICK, 1.0, random_get_within_range(1.6, 2.0));
    }
}
player_process:: (pEntity: s32)
{
    player, ent := getPlayerFromPEntity(pEntity);
    player.pCollider = collider_add(ent.fpos, 32, Collider.Group.HITS_PLAYER, false, true);
}
player_update :: (pEntity: s32, dt : float)
{
    p, e := getPlayerFromPEntity(pEntity);
    l := light_getById(p.pLight);
    l.fpos = e.fpos;
    l.direction = atan2(-(g.mouseWorld - e.fpos).y, (g.mouseWorld - e.fpos).x) - 1.579;
    l.intensity = cast(u8)(clamp(0., 255., ((1500. - length(-e.fpos)) / 1500 * 255)));
    
    if p.hp < 100.
        p.hp += 1.*dt;
    if collider_isHit(p.pCollider)
    {
        sound_play(SfxId.HIT, 1., random_get_within_range(0.8, 1.));
        p.hp -= 33.;
    }
    if p.hp <= 0. && p.pEffectDeath == 0
    {
        p.ded = true;
        p.pEffectDeath = effect_create(e.fpos, Effect.Type.EXPLOSION, 250, rl.ORANGE);
        return;
    }
    
    e.fpos += e.fvel*60*dt;
}
player_draw :: (pEntity: s32)
{
    p, e := getPlayerFromPEntity(pEntity);
    if p.ded 
        return;
    e.dpos = e.fpos;
    dir := -1.;
    if p.aim.x > e.fpos.x
        dir = 1.;
    rl.DrawTexturePro(g.content.textures[e.pTexture],
        .{0,0, dir * 32,64},
        .{e.dpos.x, e.dpos.y, 32, 64},
        .{16, 32},
        0, rl.RED);
}
hud_draw :: ()
{
    player, playerEntity := getPlayerFromPEntity(g.player);
    if player.ded 
        return;
    clr := rl.DARKGREEN;
    if player.hp < 60
        clr = rl.GOLD;
    if player.hp < 33
        clr = rl.MAROON;
    rl.DrawRectangle(0, xx(g.screenSize.y - 16.), xx(g.screenSize.x * player.hp / 100.), 16, clr);
    if collider_isHit(player.pCollider)
        rl.DrawRectangle(0,0, xx g.screenSize.x, xx g.screenSize.y, rl.WHITE);
}

