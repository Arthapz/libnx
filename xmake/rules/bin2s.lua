function string:replace(substring, replacement, n)
    return (self:gsub(substring:gsub("%p", "%%%0"), replacement:gsub("%%", "%%%%"), n))
end

rule("bin2s")
before_build(function(target, opt)
    import("core.base.option")
    import("utils.progress")

    local function GenerateEmbedHeader(filepath, targetpath)
        local bufferSize = 1024 * 1024

        progress.show(opt.progress, "${color.build.object}embedding %s", filepath)

        local resource = assert(io.open(filepath, "rb"))
        local targetFile = assert(io.open(targetpath, "w+"))

        local resourceSize = resource:size()

        local remainingSize = resourceSize
        local headerSize = 0

        local var_name = path.basename(targetpath)
        targetFile:write(format([[
                    #pragma once

                    #ifdef __cplusplus
                        #include <cstddef>
                        #include <cstdint>
                    #else
                        #include <stddef.h>
                        #include <stdint.h>
                    #endif

                    #ifdef __cplusplus >= 201103L
                        #include <array>

                        static constexpr std::size_t %s_size = %s;
                        static constexpr auto %s = std::array<std::uint8_t, %s_size> {
                    #else
                        #ifdef __cplusplus
                            static const std::size_t %s_size = %s;
                            static const std::uint8_t %s[] = {
                        #else
                            static const size_t %s_size = %s;
                            static const uint8_t %s[] = {
                        #endif
                    #endif
                    ]], var_name, resourceSize, var_name, var_name,
            var_name, resourceSize, var_name,
            var_name, resourceSize, var_name
        ))

        while remainingSize > 0 do
            local readSize = math.min(remainingSize, bufferSize)
            local data = resource:read(readSize)
            remainingSize = remainingSize - readSize

            local headerContentTable = {}
            for i = 1, #data do
                table.insert(headerContentTable, string.format("%d,", data:byte(i)))
            end
            local content = table.concat(headerContentTable)

            headerSize = headerSize + #content

            targetFile:write(content)
        end

        targetFile:write(format([[
                    };

                    #ifdef __cplusplus
                        #ifdef __cplusplus >= 201103L
                            static const auto %s_end[] = std::end(%s);
                        #else
                            static const std::uint8_t *%s_end[] = %s + %s_size;
                        #endif
                    #else
                        static const uint8_t *%s_end = %s + %s_size;
                    #endif
                ]], var_name, var_name, var_name, var_name, var_name, var_name, var_name, var_name))

        resource:close()
        targetFile:close()
    end

    for _, sourcebatch in pairs(target:sourcebatches()) do
        if sourcebatch.rulename == "bin2s" then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local targetpath = path.join("$(buildir)", path.filename(sourcefile):gsub("%.", "_") .. ".h")
                if option.get("rebuild") or os.mtime(sourcefile) >= os.mtime(targetpath) then
                    GenerateEmbedHeader(sourcefile, targetpath)
                end
            end
        end
    end
end)
