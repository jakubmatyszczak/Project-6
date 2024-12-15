
LightSource :: struct
{
    enabled : bool;
    fpos : Vector2;
    radius : float;
    intensity: u8;
    angle : float;
    direction : float;
    tint : rl.Color;
}
Lights :: struct
{
    maxLights :: 1024;
    texture : rl.RenderTexture2D;
    instances : [maxLights+1]LightSource;
    setup : [maxLights+1]bool;
}
light_getById :: (id: s64) -> *LightSource {return *g.light.instances[id];}
light_create :: (pos : Vector2, radius: float, intensity: float, tint: rl.Color = rl.WHITE) -> id: s32
{
    for 0..g.light.maxLights
    {
        if g.light.setup[it]
            continue;
        g.light.instances[it] = .{enabled=false, fpos=pos, radius=radius, intensity=cast(u8)(intensity*255)};
        g.light.instances[it].tint = .{tint.r, tint.g, tint.b, g.light.instances[it].intensity};
        g.light.setup[it] = true;
        return xx it;
    }
    return -1;
}
light_create :: (pos : Vector2, radius: float, intensity: float, angle: float) -> id: s32
{
    id := light_create(pos, radius, intensity);
    if id < 0
        return id;
    g.light.instances[id].angle = angle;
    return id;
}
light_delete :: (id: s32) {g.light.setup[id] = false;}
light_enable :: (id: s32, enable: bool)
{
    if g.light.setup[id]
        g.light.instances[id].enabled = enable;
}
light_process :: ()
{
    rl.BeginTextureMode(g.light.texture);
    rl.ClearBackground(rl.BLACK);
    for 0..g.light.maxLights
    {
        if !(g.light.setup[it] && g.light.instances[it].enabled)
            continue;
        l := light_getById(it);
        windowPos := rl.GetWorldToScreen2D(l.fpos, g.camera);
		windowPos.y = g.light.texture.texture.height - windowPos.y;  // dunno why this is needed
        
        tintDark := l.tint;
        tintDark.a /= 4;
        if l.angle == 0   // Light is circular
        {
            rl.DrawCircleV(windowPos, l.radius, tintDark);
            rl.DrawCircleV(windowPos, l.radius * 0.5, .{l.tint.r, l.tint.g, l.tint.b,
                                l.intensity - l.intensity / 4});
            continue;
        }
        //Light is conical
        rl.DrawCircleV(windowPos, l.radius / 4, tintDark);
        p2 := rotate(.{0. , l.radius}, l.direction + l.angle * 0.75);
        p3 := rotate(.{0. , l.radius}, l.direction - l.angle * 0.75);
        rl.DrawTriangle(windowPos, windowPos + p2, windowPos + p3, tintDark);
        p2 = rotate(.{0. , l.radius}, l.direction + l.angle * 0.5);
        p3 = rotate(.{0. , l.radius}, l.direction - l.angle * 0.5);
        rl.DrawTriangle(windowPos, windowPos + p2*1.2, windowPos + p3*1.2, tintDark);
        rl.DrawTriangle(windowPos, windowPos + p2, windowPos + p3, tintDark);
    }
    rl.EndTextureMode();
}
light_draw :: ()
{
    darkClr : u8 : 250;
    rl.BeginBlendMode(xx rl.rlBlendMode.MULTIPLIED);
	rl.DrawTexturePro(g.light.texture.texture,
	    .{0, 0, g.screenSize.x, g.screenSize.y},
	    .{0, 0, g.screenSize.x, g.screenSize.y},
	    .{},
		0.,
		.{darkClr, darkClr, darkClr, darkClr});
	rl.EndBlendMode();
}

