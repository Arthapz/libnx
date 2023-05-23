includes("xmake/**.lua")

target("nx")
    set_kind("$(kind)")
    add_rules("mode.debug", "mode.release")

    add_rules("bin2s")

    set_languages("gnu11")

    add_defines("LIBNX_NO_DEPRECATION")

    add_files("nx/**.c")
    add_files("nx/**.s")
    add_files("nx/data/default_font.bin", {rule = "bin2s", force = {rule = "bin2s"}})

    add_headerfiles("nx/include/(**.h)")
    add_headerfiles("nx/external/bsd/include/(**.h)")
    add_headerfiles("$(buildir)/(**.h)")

    add_includedirs("nx/include")
    add_includedirs("nx/include/switch")
    add_includedirs("nx/external/bsd/include")
    add_includedirs("$(buildir)")
