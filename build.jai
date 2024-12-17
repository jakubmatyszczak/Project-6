#import "Compiler";
Basic :: #import "Basic";

#if OS == .WINDOWS
{
    Windows_Resources :: #import "Windows_Resources";
    Ico_File :: #import "Ico_File";
}

#run {
    w := compiler_create_workspace();
    options := get_build_options(w);
    args := options.compile_time_command_line;
    isReleaseBuild := false;
    for arg : args 
    {
        if arg == 
        {
            case "release";
            {
                Basic.print("Building in Release mode.\n");
                isReleaseBuild = true;
                options.backend = .LLVM;
                set_optimization(*options, .OPTIMIZED);
            }
        }
    }
    if !isReleaseBuild
        set_optimization(*options, .DEBUG);

    options.output_executable_name = "no6";
    set_build_options(options, w);

    add_build_file("game.jai", w);
    set_build_options_dc(.{do_output=false});
    
    #if OS == .WINDOWS
    {
        ico_data := create_ico_file_from_bitmap_filename("res\\icon.png");
        defer free(ico_data);
        if !ico_data then 
            print("Could not load image for icon.\n");
        Windows_Resources.set_icon_by_data(exe_name, ico_data);
        manifest_options: Windows_Resources.Manifest_Options;
        Windows_Resources.add_manifest_to_executable(exe_name, manifest_options);
    }
}

