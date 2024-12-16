Basic :: #import "Basic";
#import "Math";
#import "Random";
rl :: #import "raylib";
#load "src/global.jai";
#load "src/entities.jai";

main :: ()
{
    random_seed(Basic.current_time_monotonic().low);
    g.screenSize = .{1920, 1080};
    rl.InitWindow(xx g.screenSize.x, xx g.screenSize.y, "no.6");
    rl.InitAudioDevice();
    music := rl.LoadMusicStream("res/sfx/battle.ogg");
    content_init(*g.content);
    rl.SetTargetFPS(60);
    // rl.ToggleFullscreen();

    while game(*music)
        reset_state();

    if rl.IsWindowFullscreen()
        rl.ToggleFullscreen();
    rl.CloseWindow();
}
game :: (music: *rl.Music) -> bool
{
    entity_create(Entity.Arch.UNKNOWN, .{}, 0); // Dummy entity to occupy index 0
    g.light.texture = rl.LoadRenderTexture(xx g.screenSize.x, xx g.screenSize.y);
    defer rl.UnloadRenderTexture(g.light.texture);
    g.camera = .{offset= .{xx (g.screenSize.x / 2), xx (g.screenSize.y / 2)},
                    target=.{0,0}, rotation=0., zoom=1.};
    g.player = player_create(.{0,0});
    mainLight := light_getById(light_create(.{0., 0.}, 1000., 0.8));

    win := false;
    start := false;

    endTime : float;
    spawnBasic := 3.;
    spawnRingo := 8.;
    spawnTimerBasic := 0.;
    spawnTimerRingo := -3.;
    spawnTimerBoss := -100.;
    difficultyBumpTimer := -30.;
    bossFightStart : bool = false;
    bossFightInProgress : bool = false;
    alaramsTriggered := 0;
    level := 0;
    rl.SeekMusicStream(music, 0.);
    rl.PlayMusicStream(music);
    while !start
    {
        rl.UpdateMusicStream(music);
        rl.BeginDrawing();
        rl.DrawRectangle(100, 100, xx (g.screenSize.x - 200), xx (g.screenSize.y - 200), rl.BLACK);
        rl.DrawText("Use WSAD to move, mouse to AIM, and left mouse button to SHOOT!", 
            xx (g.screenSize.x/2 - 800), xx (g.screenSize.y/2 - 100), 38, rl.WHITE);
        rl.DrawText("Press ENTER to start.", xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2), 16, rl.WHITE);
        rl.EndDrawing();
        if rl.IsKeyReleased(rl.KeyboardKey.ENTER)
            start = true;
    }
    enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.RINGO);
    enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.BASIC);
    enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.BASIC);
    enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.BASIC);
    enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.BASIC);
    while 1
    {
        rl.UpdateMusicStream(music);
        dt := rl.GetFrameTime();
        g.time += dt;
        g.mouseScreen = rl.GetMousePosition();
        g.mouseWorld = rl.GetScreenToWorld2D(g.mouseScreen, g.camera);
        g.mouseScreen.y = g.screenSize.y - g.mouseScreen.y;

        // process
        entities_process();
        collider_process();

        if !bossFightStart
        {
            spawnTimerBasic += dt;
            spawnTimerRingo += dt;
            spawnTimerBoss += dt;
            difficultyBumpTimer += dt;
        }
        if difficultyBumpTimer > 0
        {
            sound_play(SfxId.ALARM, 0.7, 2.);
            difficultyBumpTimer = -30.;
            spawnBasic *= 0.8;
            spawnRingo *= 0.9;
            mainLight.intensity = xx(mainLight.intensity * 0.7);
            mainLight.radius *= 0.9;
        }
        if spawnTimerBasic > spawnBasic
        {
            spawnTimerBasic = 0.;
            for 0..level*2 
                enemy_create(polarToXY(random_get_within_range(0. , 6.283), random_get_within_range(800, 1500)), Enemy.Type.BASIC);
        }
        if spawnTimerRingo > spawnRingo
        {
            spawnTimerRingo = 0.;
            for 0..level
                enemy_create(polarToXY(random_get_within_range(0. , 6.283), 1250), Enemy.Type.RINGO);
        }
        if spawnTimerBoss > 0
        {
            bossFightStart = true;
            if bossFightInProgress && frame.nEnemies == 0 && !win
            {
                endTime = g.time;
                win = true;
            }
            if frame.nEnemies == 0 && !bossFightInProgress
            {
                bossFightInProgress = true;
                mainLight.tint = rl.RED;
                for 0..20
                {
                    enemy_create(polarToXY(random_get_within_range(0. , 6.283), random_get_within_range(2000, 2250)), Enemy.Type.RINGO);
                    enemy_create(polarToXY(random_get_within_range(0. , 6.283), random_get_within_range(3000, 3500)), Enemy.Type.BASIC);
                }
            }
        }
        if bossFightInProgress
        {
            
            if alaramsTriggered < 3 && !rl.IsSoundPlaying(g.content.sfx[SfxId.ALARM])
            {
                alaramsTriggered += 1;
                sound_play(SfxId.ALARM, 1., 1.5);
            }
            mainLight.intensity = cast(u8)((((sin(g.time*3) + 1.) / 2) * 0.6) * 255);    
        }

        //input
        if !win
        {
            player_input(g.player,
                    up=rl.IsKeyDown(rl.KeyboardKey.KEY_W),
                    down=rl.IsKeyDown(rl.KeyboardKey.KEY_S),
                    left=rl.IsKeyDown(rl.KeyboardKey.KEY_A),
                    right=rl.IsKeyDown(rl.KeyboardKey.KEY_D),
                    interact=rl.IsKeyPressed(rl.KeyboardKey.KEY_F),
                    shoot=rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
                );
        }
        if(rl.IsKeyPressed(cast(s32)rl.KeyboardKey.KEY_ENTER))
           return true;
        if(rl.IsKeyPressed(cast(s32)rl.KeyboardKey.KEY_ESCAPE))
            return false;
        
        //update
        entities_update(dt);

        //camera
        p, e := getPlayerFromPEntity(g.player);
        g.camera.target = p.aim;
        light_process();

        //draw
        rl.BeginDrawing();
        rl.BeginMode2D(g.camera);
            rl.ClearBackground(.{38, 20, 20, 255});
            for x: -20..20
                for y: -20..20
                    rl.DrawTextureEx(g.content.textures[TexId.HEX], .{x * 2*64., y * 2*64.}, 0, 4*2, rl.WHITE);
            entities_draw();
        rl.EndMode2D();
        light_draw();
        hud_draw();
        if win
        {
            rl.DrawRectangle(100, 100, xx (g.screenSize.x - 200), xx (g.screenSize.y - 200), rl.BLACK);
            rl.DrawText("You win!", xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2 - 100), 38, rl.WHITE);
            rl.DrawText(rl.TextFormat("Finished in: % seconds", Basic.formatFloat(endTime, trailing_width = 2)), xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2 - 140), 38, rl.WHITE);
            rl.DrawText("Press ESCAPE to quit.", xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2), 16, rl.WHITE);
            rl.DrawText("Press ENTER to restart.", xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2+100), 16, rl.WHITE);
        }
        if p.ded
        {
            if(endTime < 1)
                endTime = g.time;
            rl.DrawRectangle(100, 100, xx (g.screenSize.x - 200), xx (g.screenSize.y - 200), .{0,0,0,180});
            rl.DrawText("DE4D", xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2 - 100), 38, rl.WHITE);
            rl.DrawText(rl.TextFormat("Survived for: % seconds", Basic.formatFloat(endTime, trailing_width = 2)), xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2 - 50), 16, rl.WHITE);
            rl.DrawText("Press ESCAPE to quit.", xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2), 16, rl.WHITE);
            rl.DrawText("Press ENTER to restart.", xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2+100), 16, rl.WHITE);
        }

        rl.EndDrawing();

        // finish
        collider_finish();
        memset(*frame, 0, size_of(FrameData));
    }
    return false;
}
