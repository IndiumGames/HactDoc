--!
--! HactDoc
--! =======
--!
--! Extracts documentation from source code for Sphinx.
--!


--!
--! Get a character count times.
--!
local function GetChar(char, count)
    if count <= 0 then
        return ""
    end
    
    return char .. GetChar(char, count - 1)
end


--!
--! Print table recursively.
--!
local function PrintRecursively(tbl, recursionLevel)
    recursionLevel = recursionLevel or 0
    
    for _, value in ipairs(tbl) do
        print(GetChar("| \t", recursionLevel) .. tostring(value))
        
        for key, value in pairs(value) do
            if type(key) == "string" and (key:match("identifier$")) then
                print(GetChar("\t", recursionLevel) .. " > "
                      .. tostring(key) .. " \t" .. tostring(value):gsub("\n", "\n" .. GetChar("\t", recursionLevel + 3)))
            end
        end
        
        PrintRecursively(value, recursionLevel + 1)
    end
end


--!
--! HactDoc module.
--!
local HactDoc = {
    Cpp = require("hactdoc_cpp");
    --Lua = {};
    
    objects = {};
}


--!
--! Parse a source file.
--!
--! :param file:       The source file to parse
--! :param hierarchy:  The object hierarchy.
--!
function HactDoc.ParseFile(file, hierarchy)
    print()
    --print("*******************************************************************")
    print("Parsing file: ", file)
    local start = os.clock()
    --print("===================================================================")
    
    if file:match("%.h$") or file:match("%.cpp$") then
        HactDoc.Cpp.ParseFile(file, hierarchy)
    elseif file:match("%.lua$") then
        print("Lua currently unsupported...")
    end
    
    --print("===================================================================")
    print("    Parsing done, took: " .. (os.clock() - start) .. " s")
    --print("*******************************************************************")
    print()
end


--!
--! HactDoc main function.
--!
--! :param sourceFiles:  List of source files to parse.
--! :param outputDir:    Output directory (defaults to working directory).
--!
function HactDoc.HactDoc(sourceFiles, outputDir)
    -- Output directory defaults to working directory
    outputDir = outputDir or "."
    
    if not sourceFiles then
        error(2, "No source files specified")
    end
    
    local start = os.clock()
    
    local hierarchy = {}
    
    for _, sourceFile in ipairs(sourceFiles) do
        HactDoc.ParseFile(sourceFile, hierarchy)
    end
    
    
    print()
    print(":::HIERARCHY:::")
    PrintRecursively(hierarchy)
    print()
    
    print()
    print("Parsed all files, took: " .. (os.clock() - start) .. " s")
    print("Saving output to directory: ", outputDir)
end


HactDoc.HactDoc{
    --[[
    "../HactEngine/src/audio.h";
    "../HactEngine/src/audio.cpp";
    "../HactEngine/src/audiomanager.h";
    "../HactEngine/src/audiomanager.cpp";
    --]]
    "../HactEngine/src/chronotime.h";
    "../HactEngine/src/chronotime.cpp";
    --[[
    "../HactEngine/src/container.h";
    "../HactEngine/src/container.cpp";
    "../HactEngine/src/debug.h";
    "../HactEngine/src/debug.cpp";
    "../HactEngine/src/editor.h";
    "../HactEngine/src/editor.cpp";
    "../HactEngine/src/editorwindow.h";
    "../HactEngine/src/editorwindow.cpp";
    "../HactEngine/src/entity.h";
    "../HactEngine/src/entity.cpp";
    "../HactEngine/src/gameengine.h";
    "../HactEngine/src/gameengine.cpp";
    "../HactEngine/src/hierarchy.h";
    "../HactEngine/src/hierarchy.cpp";
    "../HactEngine/src/input.h";
    "../HactEngine/src/input.cpp";
    "../HactEngine/src/logger.h";
    "../HactEngine/src/logger.cpp";
    "../HactEngine/src/loglistener.h";
    "../HactEngine/src/loglistener.cpp";
    "../HactEngine/src/logmessage.h";
    "../HactEngine/src/logqueue.h";
    "../HactEngine/src/logqueue.cpp";
    "../HactEngine/src/main.cpp";
    "../HactEngine/src/mesh.h";
    "../HactEngine/src/mesh.cpp";
    "../HactEngine/src/property.h";
    "../HactEngine/src/property.cpp";
    "../HactEngine/src/resourcemanager.h";
    "../HactEngine/src/resourcemanager.cpp";
    "../HactEngine/src/resourceutil.h";
    "../HactEngine/src/resourceutil.cpp";
    "../HactEngine/src/scriptingengine.h";
    "../HactEngine/src/scriptingengine.cpp";
    "../HactEngine/src/shaderprogram.h";
    "../HactEngine/src/shaderprogram.cpp";
    "../HactEngine/src/text.h";
    "../HactEngine/src/text.cpp";
    "../HactEngine/src/texture.h";
    "../HactEngine/src/texture.cpp";
    "../HactEngine/src/thread.h";
    "../HactEngine/src/thread.cpp";
    "../HactEngine/src/util.h";
    "../HactEngine/src/util.cpp";
    "../HactEngine/src/xmlelement.h";
    "../HactEngine/src/xmlelement.cpp";
    "../HactEngine/src/xmlutils.h";
    "../HactEngine/src/xmlutils.cpp";
    --]]
}
