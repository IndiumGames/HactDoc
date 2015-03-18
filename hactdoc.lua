--!
--! HactDoc
--! =======
--!
--! Extracts documentation from source code for Sphinx.
--!


local path = select(1, ...) and select(1, ...):match(".+%.") or ""


--!
--! HactDoc module.
--!
local HactDoc = {
    parsers = {
        ["C++"] = require(path .. "hactdoc_cpp");
        --["Lua"] = require(path .. "hactdoc_lua");
    };
    
    formatters = {
        ["default"] = require(path .. "hactdoc_formatter");
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
--! Write to file.
--!
--! :param filePath:  File to write to.
--! :param content:   Content to write.
--!
local function WriteToFile(filePath, content)
    -- Open the output file
    local file, errorMessage = io.open(filePath, "w")
    
    if file then
        file:write(content)
        file:close()
    else
        error("Failed to write to file '" .. filePath .. "':\n"
              .. errorMessage, 2)
    end
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
--! :param domain:     The domain to use.
--!
--! :returns: The documentation string.
--!
function HactDoc.Format(object, formatter, domain)
    print()
    --print("*******************************************************************")
    print("Formatting object: ", object.identifier)
    local start = os.clock()
    --print("===================================================================")
    
    -- Format the object using the parser
    local formatted = HactDoc.formatters[formatter].Format(object, domain)
    
    --print("===================================================================")
    print("    Formatting done, took: " .. (os.clock() - start) .. " s")
    --print("*******************************************************************")
    print()
    
    return formatted
end


--!
--! HactDoc main function.
--!
--! :param parameters:  "parser"    - The parser to use
--!                                   (defaults to "C++").
--!                     "formatter" - The formatter to use
--!                                   (defaults to "default").
--!                     "sourceDir" - Source code directory
--!                                   (defaults to working directory).
--!                     "outputDir" - Output directory
--!                                   (defaults to working directory).
--!                     #           - List of source files to parse.
--!
function HactDoc.HactDoc(parameters)
    -- Default parser to "C++"
    local parser = parameters.parser or "C++"
    
    -- Default formatter to "default"
    local formatter = parameters.formatter or "default"
    
    -- Source code directory
    local sourceDir = (parameters.sourceDir or "."):gsub("/*$", "")

    -- Output directory (defaults to working directory)
    local outputDir = (parameters.outputDir or "."):gsub("/*$", "")
    
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
    
    -- Create the documentation object hierarchy (and save some info in it)
    local hierarchy = {
        sourceDir = sourceDir;
    }
    
    for _, sourceFile in ipairs(parameters) do
        HactDoc.ParseFile(sourceDir .. "/" .. sourceFile, hierarchy, parser)
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
    
    ---[[
    start = os.clock()
    
    -- The documentation index
    local index = {
        "HactDoc index";
        "=============";
        "";
        ".. toctree::";
        "    ";
    }
    
    -- Iterate over root level document objects
    for i, object in ipairs(hierarchy) do
        -- Format the documentation object
        local formattedDoc = HactDoc.Format(object, formatter, hierarchy.domain)
        
        print()
        print(":::Formatted documentation: ", object.identifier)
        print(formattedDoc)
        print()
        
        -- Output file name (without extension)
        local fileName = (object.identifier or "object_" .. i)
        
        -- Add entry to the index (remove extension)
        index[#index + 1] = "    " .. fileName
        
        -- Output file path
        local filePath = outputDir .. "/" .. fileName .. ".rst"
        
        -- Write to output file
        WriteToFile(filePath, formattedDoc)
    end
    
    -- Write index file
    WriteToFile(outputDir .. "/index.rst", table.concat(index, "\n") .. "\n\n")
    
    print()
    print(":::Formatted all files, took: " .. (os.clock() - start) .. " s")
    print()
    --]]
    
    ---[[
    print()
    print("Saving output to directory: ", outputDir)
    --]]
end


return HactDoc
