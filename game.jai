Basic :: #import "Basic";
#import "Math";
#import "Random";
rl :: #import "raylib";
#load "src/global.jai";
#load "src/level.jai";
#load "src/entities.jai";

main :: ()
{
    random_seed(Basic.current_time_monotonic().low);

    entity_create(Entity.Arch.UNKNOWN, .{}, 0); // Dummy entity to occupy index 0

    g.screenSize = .{1920, 1080};
    rl.InitWindow(xx g.screenSize.x, xx g.screenSize.y, "no.6");
    // rl.ToggleFullscreen();
    rl.SetTargetFPS(75);
    content_init(*g.content);

    g.light.texture = rl.LoadRenderTexture(xx g.screenSize.x, xx g.screenSize.y);
    g.camera = .{offset= .{xx (g.screenSize.x / 2), xx (g.screenSize.y / 2)},
                    target=.{0,0}, rotation=0., zoom=1.};
    g.player = player_create(.{0,0});

    win := false;
    mainLight := light_getById(light_create(.{0., 0.}, 1000., 0.8));

            // enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.RINGO);
            // enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.BASIC);
            // enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.BASIC);
            // enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.BASIC);
            enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.BASIC);

    spawnTimerBasic := 0.;
    spawnTimerRingo := -5.;
    spawnTimerBoss := -1.;
    bossFightStart : bool = false;
    bossFightInProgress : bool = false;
    while 1
    {
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
            spawnTimerBasic +=dt;
            spawnTimerRingo +=dt;
            spawnTimerBoss +=dt;
        }
        if spawnTimerBasic > 3.
        {
            spawnTimerBasic = 0.;
            enemy_create(polarToXY(random_get_within_range(0. , 6.283), 800), Enemy.Type.BASIC);
        }
        if spawnTimerRingo > 8.
        {
            spawnTimerRingo = 0.;
            enemy_create(polarToXY(random_get_within_range(0. , 6.283), 1000), Enemy.Type.RINGO);
        }
        if spawnTimerBoss > 0
        {
            bossFightStart = true;
            if bossFightInProgress && frame.nEnemies == 0
                win = true;
            if frame.nEnemies == 0 && !bossFightInProgress
            {
                bossFightInProgress = true;
                mainLight.tint = rl.RED;
                for 0..20
                {
                    enemy_create(polarToXY(random_get_within_range(0. , 6.283), 2000), Enemy.Type.RINGO);
                    enemy_create(polarToXY(random_get_within_range(0. , 6.283), 3000), Enemy.Type.BASIC);
                }
            }
        }
        if bossFightInProgress
        {
            mainLight.intensity = cast(u8)((((sin(g.time*3) + 1.) / 2) * 0.8) * 255); 
            Basic.print("main: %\n", mainLight.intensity);
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
           break;
        
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
        if win
        {
            rl.DrawRectangle(100, 100, xx (g.screenSize.x - 200), xx (g.screenSize.y - 200), rl.BLACK);
            rl.DrawText("You win!", xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2 - 100), 38, rl.WHITE);
            rl.DrawText("Press ENTER to quit.", xx (g.screenSize.x/2 - 100), xx (g.screenSize.y/2), 16, rl.WHITE);
        }
        rl.DrawText(rl.TextFormat("Entities: %", g.nEntities), 20, 20, 18, rl.WHITE);
        rl.DrawFPS(20, 40);
        rl.DrawText(rl.TextFormat("FrameTime: %", rl.GetFrameTime()), 20, 60, 18, rl.WHITE);
        rl.EndDrawing();

        // finish
        collider_finish();
        memset(*frame, 0, size_of(FrameData));
    }
    if rl.IsWindowFullscreen()
        rl.ToggleFullscreen();
    rl.CloseWindow();
}
