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

    g.screenSize = .{1366, 768};
    rl.InitWindow(xx g.screenSize.x, xx g.screenSize.y, "no.6");
    rl.SetTargetFPS(75);
    content_init(*g.content);

    g.light.texture = rl.LoadRenderTexture(xx g.screenSize.x, xx g.screenSize.y);
    g.camera = .{offset= .{xx (g.screenSize.x / 2), xx (g.screenSize.y / 2)},
                    target=.{0,0}, rotation=0., zoom=1.};
    g.player = player_create(.{0,0});

    win := false;
    light_enable(light_create(.{0., 0.}, 1000., 0.2), true);

    enemy_create(.{500, 300}, Enemy.Type.BASIC);

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
            rl.DrawRectangle(100,100,400,300, rl.BLACK);
            rl.DrawText("You win!", 200,200,38, rl.WHITE);
            rl.DrawText("Press ENTER to quit.", 200,250,16, rl.WHITE);
        }
        rl.EndDrawing();

        // finish
        collider_finish();
    }
}
