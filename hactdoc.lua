--!
--! HactDoc
--! =======
--!
--! Extracts documentation from source code for Sphinx.
--!


--!
--! HactDoc module.
--!
local HactDoc = {
    parsers = {
        ["C++"] = require("hactdoc_cpp");
        --["Lua"] = require("hactdoc_lua");
    };
    
    formatters = {
        ["default"] = require("hactdoc_formatter");
    };
}


--!
--! Get a string a given amount of times.
--!
--! :param string:  The string to concatenate.
--! :param amount:  The amount of copies to concatenate.
--!
--! :returns: The concatenated string.
--!
local function GetString(string, amount)
    if amount <= 0 then
        return ""
    end
    
    return string .. GetString(string, amount - 1)
end


--!
--! Pad a string with spaces (for pretty printing).
--!
--! :param string:  The string to pad.
--! :param length:  The wanted length.
--!
--! :returns: The original string with padding.
--!
local function Pad(string, length)
    string = tostring(string)
    length = length or 20
    return string .. GetString(" ", length - #string)
end


--!
--! Print hierarchy recursively.
--!
local function PrintHierarchy(node, recursionLevel)
    recursionLevel = recursionLevel or 0
    
    for _, object in ipairs(node) do
        local sourceFiles = ""
        
        for _, sourceFile in ipairs(object.sourceFiles) do
            sourceFiles = #sourceFiles > 0 and (sourceFiles .. "; " .. sourceFile)
                                        or sourceFile
        end
        
        print(GetString(" |  ", recursionLevel)
              .. Pad(object.identifier, 40 - recursionLevel * 4)
              .. " (" .. Pad(tostring(object.type) .. ";", 10)
              .. " from '" .. sourceFiles .. "')")
        
        --[[
        print(GetString(" | \t", recursionLevel) .. tostring(value))
        
        for key, value in pairs(value) do
            if type(key) == "string" and (key:match("^identifier$")
                                          or key:match("^type$")
                                          or key:match("^description$")
                                          or key:match("^signature$")) then
                print(GetString(" | \t", recursionLevel) .. " |> "
                      .. tostring(key) .. " \t" .. tostring(value):gsub("\n",
                      "\n" .. GetString("\t", recursionLevel + 2)))
            end
        end
        --]]
        
        PrintHierarchy(object, recursionLevel + 1)
    end
end


--!
--! Sort a table alphabetically.
--!
--! :param object:  Table (or object) to sort.
--!
--! :returns: The sorted table (or object).
--!
local function SortAlphabetically(object)
    local function SortByIdentifier(a, b)
        return tostring(a.identifier) < tostring(b.identifier)
    end
    
    -- Sort by identifier
    table.sort(object, SortByIdentifier)
    
    -- Return the sorted table
    return object
end


--!
--! Parse a source file.
--!
--! :param file:       The source file to parse
--! :param hierarchy:  The object hierarchy.
--! :param parser:     The parser to use.
--!
function HactDoc.ParseFile(file, hierarchy, parser)
    print()
    --print("*******************************************************************")
    print("Parsing file: ", file)
    local start = os.clock()
    --print("===================================================================")
    
    -- Parse the file using the parser
    HactDoc.parsers[parser].ParseFile(file, hierarchy)
    
    --print("===================================================================")
    print("    Parsing done, took: " .. (os.clock() - start) .. " s")
    --print("*******************************************************************")
    print()
end


--!
--! Format a documentation object into a documentation string.
--!
--! :param object:     The documentation object to format.
--! :param formatter:  The formatter to use.
--!
--! :returns: The documentation string.
--!
function HactDoc.Format(object, formatter)
    print()
    --print("*******************************************************************")
    print("Formatting object: ", object.identifier)
    local start = os.clock()
    --print("===================================================================")
    
    -- Format the object using the parser
    -- TODO: How to specify the domain?
    local formatted = HactDoc.formatters[formatter].Format(object, "cpp")
    
    --print("===================================================================")
    print("    Formatting done, took: " .. (os.clock() - start) .. " s")
    --print("*******************************************************************")
    print()
    
    return formatted
end


--!
--! HactDoc main function.
--!
--! :param parameters:  "parser"    - The parser to use (defaults to "C++").
--!                     "formatter" - The formatter to use
--!                                   (defaults to "default").
--!                     "outputDir" - Output directory
--!                                   (defaults to working directory).
--!                     #           - List of source files to parse.
--!
function HactDoc.HactDoc(parameters)
    -- Default parser to "C++"
    local parser = parameters.parser or "C++"
    
    -- Default formatter to "default"
    local formatter = parameters.formatter or "default"
    
    -- Output directory defaults to working directory
    local outputDir = parameters.outputDir or "."
    
    if not HactDoc.parsers[parser] then
        error("Parser not found: " .. tostring(parser), 2)
    end
    
    if not HactDoc.formatters[formatter] then
        error("Formatter not found: " .. tostring(formatter), 2)
    end
    
    if #parameters == 0 then
        error("No source files specified", 2)
    end
    
    local start = os.clock()
    
    local hierarchy = {}
    
    for _, sourceFile in ipairs(parameters) do
        HactDoc.ParseFile(sourceFile, hierarchy, parser)
    end
    
    print()
    print(":::Parsed all files, took: " .. (os.clock() - start) .. " s")
    print()
    
    -- Sort root level nodes in the hierarchy
    hierarchy = SortAlphabetically(hierarchy)
    
    print()
    print(":::HIERARCHY")
    PrintHierarchy(hierarchy)
    print()
    
    start = os.clock()
    
    for _, object in ipairs(hierarchy) do
        local formattedDoc = HactDoc.Format(object, formatter)
        
        print()
        print(":::Formatted documentation: ", object.identifier)
        print(formattedDoc)
        print()
    end
    
    print()
    print(":::Formatted all files, took: " .. (os.clock() - start) .. " s")
    print()
    
    print()
    print("Saving output to directory: ", outputDir)
end


HactDoc.HactDoc{
    parser = "C++";
    formatter = "default";
    
    "../HactEngine/src/audio.h";
    "../HactEngine/src/audio.cpp";
    "../HactEngine/src/audiomanager.h";
    "../HactEngine/src/audiomanager.cpp";
    "../HactEngine/src/chronotime.h";
    "../HactEngine/src/chronotime.cpp";
    -- FIXME: Container and OrderedContainer are not recognized as a classes
    "../HactEngine/src/container.h";
    -- FIXME: Will not parse correctly, because of template class
    --"../HactEngine/src/container.cpp";
    -- FIXME: Problem with inheriting parents
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
    -- FIXME: Hierarchy is not recognized as a class
    "../HactEngine/src/hierarchy.h";
    -- FIXME: Will not parse correctly, because of (very weird) template class
    --"../HactEngine/src/hierarchy.cpp";
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
    -- FIXME: Problem with inheriting parents
    "../HactEngine/src/xmlutils.cpp";
}
