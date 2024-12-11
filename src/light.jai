
LightSource :: struct
{
    enabled : bool;
    fpos : Vector2;
    radius : float;
    intensity: u8;
}
Lights :: struct
{
    maxLights :: 32;
    texture : rl.RenderTexture2D;
    instances : [maxLights+1]LightSource;
    setup : [maxLights+1]bool;
}
light_getById :: (id: s64) -> *LightSource {return *g.light.instances[id];}
light_create :: (pos : Vector2, radius: float, intensity: float) -> id: s32
{
    for 0..g.light.maxLights
    {
        if g.light.setup[it]
            continue;
        g.light.instances[it] = .{enabled=false, fpos=pos, radius=radius, intensity=cast(u8)(intensity*255)};
        g.light.setup[it] = true;
        return xx it;
    }
    return -1;
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
        rl.DrawCircleV(windowPos, l.radius, .{255, 200, 200, l.intensity / 4 });
        rl.DrawCircleV(windowPos, l.radius * 0.4, .{255, 200, 200, l.intensity - l.intensity / 4});
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

