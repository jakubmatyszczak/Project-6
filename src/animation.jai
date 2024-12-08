Animation :: struct
{
    Transit :: enum
    {
        LERP;
        EASYIN;
        EASYOUT;
        SMOOTHSTEP;
    }
    KeyFrame :: struct
    {
        pos : Vector2;
        rot : float;
        scale : float;
        tint : Vector4;
        length : float;
        transit : Transit;
    }
    maxKeyFrames :: 8;
    active : bool;
    looped : bool;
    keyFrames : [maxKeyFrames]KeyFrame;
    keyFrame : u32;
    nKeyFrames : u32;
    currentOffset : KeyFrame;
    timer : float;
    period : float;
}
anim_start :: (animation : *Animation)
{
    if animation.nKeyFrames == 0
        return;
    animation.active = true;
    animation.keyFrame = 0;
    animation.timer = 0.;
    animation.currentOffset = animation.keyFrames[0];
}
anim_update :: (using animation : *Animation, dt: float)
{
    if !active
        return;
    timer += dt;

    if timer > keyFrames[keyFrame+1].length * period
    {
        keyFrame += 1;
        timer = 0.;
        if keyFrame >= nKeyFrames-1
        {
            if !looped
            {
                active = false;
                return;
            }
            anim_start(animation);
        }
    }
    current : *KeyFrame = *keyFrames[keyFrame];
    next : *KeyFrame = *keyFrames[keyFrame + 1];
    t: float = timer / (next.length * period);
    if next.transit ==
    {
        case Animation.Transit.LERP;
        case Animation.Transit.EASYIN;
            t = pow(t, 2);
        case Animation.Transit.EASYOUT;
            t = sqrt(t);
        case Animation.Transit.SMOOTHSTEP;
            t = t*t * (3. - 2.*t); 
    }
    currentOffset.pos = lerp(current.pos, next.pos, t);
    currentOffset.rot = lerp(current.rot, next.rot, t);
    currentOffset.scale = lerp(current.scale, next.scale, t);
    currentOffset.tint = lerp(current.tint, next.tint, t);
}
anim_getPos :: (using animation: Animation) -> Vector2  { return currentOffset.pos; }
anim_getRot :: (using animation: Animation) -> float    { return currentOffset.rot; }
anim_getScale :: (using animation: Animation) -> float  { return currentOffset.scale; }
anim_getTint :: (using animation: Animation) -> Vector4 { return currentOffset.tint; }

anim_create_hover :: (period : float, amplitude: float) -> Animation
{
    hover : Animation;
    hover.nKeyFrames = 3;
    hover.looped = true;
    hover.period = period;
    hover.keyFrames[0] = .{pos=.{0, -amplitude}, rot=0., scale=0., tint=.{}, length=0.5, transit=Animation.Transit.SMOOTHSTEP};
    hover.keyFrames[1] = .{pos=.{0, -2*amplitude}, rot=0., scale=0., tint=.{}, length=0.5, transit=Animation.Transit.SMOOTHSTEP};
    hover.keyFrames[2] = .{pos=.{0, -amplitude}, rot=0., scale=0., tint=.{}, length=0.5, transit=Animation.Transit.SMOOTHSTEP};
    return hover;
}
anim_create_jump :: (height: float) -> Animation
{
    jump : Animation;
    jump.nKeyFrames = 3;
    jump.looped = false;
    jump.period = 0.3;
    jump.keyFrames[0] = .{pos=.{0, 0}, rot=0., scale=0., tint=.{}, length=0.5, transit=Animation.Transit.EASYOUT};
    jump.keyFrames[1] = .{pos=.{0, height}, rot=0., scale=0., tint=.{}, length=0.5, transit=Animation.Transit.EASYOUT};
    jump.keyFrames[2] = .{pos=.{0, 0}, rot=0., scale=0., tint=.{}, length=0.5, transit=Animation.Transit.EASYIN};
    return jump;
}
anim_create_shake :: (amplitude: float) -> Animation
{
    shake : Animation;
    shake.nKeyFrames = 4;
    shake.looped = false;
    shake.period = 0.3;
    shake.keyFrames[0] = .{pos=.{-amplitude, 0}, rot=0., scale=0., tint=.{}, length=0.25, transit=Animation.Transit.LERP};
    shake.keyFrames[1] = .{pos=.{amplitude, 0}, rot=0., scale=0., tint=.{}, length=0.25, transit=Animation.Transit.LERP};
    shake.keyFrames[2] = .{pos=.{-amplitude, 0}, rot=0., scale=0., tint=.{}, length=0.25, transit=Animation.Transit.LERP};
    shake.keyFrames[3] = .{pos=.{0, 0}, rot=0., scale=0., tint=.{}, length=0.25, transit=Animation.Transit.EASYOUT};
    return shake;
}
