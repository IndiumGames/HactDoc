--!
--! HactDoc - C++ module
--! ====================
--!
--! This module implements C++ support for HactDoc.
--!


local Cpp = {}


--!
--! Test if a string is the beginning of a docstring.
--!
--! :param str:  The string to test.
--!
--! :returns:  True, if the string is the beginning of a docstring.
--!
local function IsDocstringBeginning(str)
    return (str:match("^%s*/%*!") or str:match("^%s*//!"))
end


--!
--! Strip the docstring.
--!
--! :param docstring:  Docstring to strip (single or multiple lines).
--!
--! :returns:  The stripped docstring.
--!
local function StripDocstring(docstring)
    -- Remove the docstring commands
    docstring = docstring:gsub("![^%s%*]*", "!", 1)
    
    -- The stripped docstring
    local strippedDocstring = ""
    
    -- Iterate over the lines in the docstring
    for line in docstring:gmatch("[^\n]+") do
        -- Strip beginning of the line
        line = line:gsub("^%s*//!?%s?", "")
        line = line:gsub("^%s*/?%*[!/]?%s?", "")
        
        strippedDocstring = strippedDocstring .. line .. "\n"
    end
    
    -- Strip whitespace and line changes at the start and end of the docstring
    strippedDocstring = strippedDocstring:gsub("^[%s\n]+", "")
    strippedDocstring = strippedDocstring:gsub("[%s\n]+$", "")
    
    return strippedDocstring
end


--!
--! Collects a docstring.
--!
--! :param object:      The documentation object.
--! :param lines:       Lines in a file.
--! :param lineNumber:  Line to begin on.
--!
--! :returns: The line where the docstring ends.
--!
local function CollectDocstring(object, lines, lineNumber)
    -- First line of the docstring
    local firstLine = lines[lineNumber]
    
    -- Check for multiline comment
    local multilineComment = (firstLine:find("/%*!") or false)
    
    -- Get commands from the first line
    local commands = (firstLine:match("%[[^%]]*%]") or "")
    commands = commands .. (firstLine:match("[<>^~]+") or "")
    
    -- Parse docstring commands
    object.commands = commands
    
    -- Strip the commands from the first line
    lines[lineNumber] = lines[lineNumber]:gsub("![^%s%*]*", "!")
    
    -- Start collecting docstring
    local docstring = ""
    
    -- Iterate over lines
    while lineNumber <= #lines do
        -- Current line
        local line = lines[lineNumber]
        
        if multilineComment then
            if not line:match("%*/") then
                -- Append the line to the docstring
                docstring = docstring .. line .. "\n"
            else
                -- Append the last line to the docstring
                docstring = docstring .. line
                
                lineNumber = lineNumber + 1
                break
            end
        else
            if line:match("^%s*//") then
                -- Append the line to the docstring
                docstring = docstring .. line .. "\n"
            else
                break
            end
        end
        
        -- Go to the next line
        lineNumber = lineNumber + 1
    end
    
    -- Strip empty line at the end of the docstring
    docstring = docstring:gsub("\n*$", "")
    
    -- Save docstring into the documentation object
    object.docstringFull = docstring
    
    -- Strip the docstring (to text only) and save the stripped docstring
    object.docstring = StripDocstring(docstring)
    
    
    return lineNumber
end


--!
--! Strip a signature.
--!
--! :param signature:  The full signature.
--!
--! :returns: The stripped signature (as Sphinx wants it).
--!
local function StripSignature(signature)
    -- Strip template (not supported by Sphinx)
    signature = signature:gsub("%s*template%s+<[^>]*>[%s\n]*", "")
    
    -- Strip type ("class", "namespace", "enum", etc)
    signature = signature:gsub("%s*enum%s+", "")
    signature = signature:gsub("%s*class%s+", "")
    signature = signature:gsub("%s*using%s+", "")
    signature = signature:gsub("%s*namespace%s+", "")
    signature = signature:gsub("%s*struct%s+", "")
    signature = signature:gsub("%s*union%s+", "")
    signature = signature:gsub("%s*typedef%s+", "")
    
    -- Strip scope (handled by the object hierarchy)
    signature = signature:gsub("%w*::", "")
    
    return signature
end


--!
--! Get object type based on signature.
--!
--! :param signature:  The object's signature..
--!
--! :returns: The object's type (as a string).
--!
local function GetObjectType(signature)
    -- Pattern to match a template
    local template = "template%s+<[^>]*>[%s\n]+"
    
    -- Identify object type
    if signature:find("^%s*namespace%s+") then
        return "namespace"
    elseif signature:find("^%s*class%s+")
           or signature:find("^%s*" .. template .. "class") then
        return "class"
    elseif signature:find("^%s*enum%s+class%s+") then
        return "enum class"
    elseif signature:find("^%s*enum%s+") then
        return "enum"
    elseif signature:find("^%s*struct%s+")
           or signature:find("^%s*" .. template .. "struct") then
        return "struct"
    elseif signature:find("^%s*union%s+")
           or signature:find("^%s*" .. template .. "union") then
        return "union"
    elseif signature:find("^%s*typedef%s+") then
        return "typedef"
    elseif signature:find("^%s*using%s+") then
        return "using"
    else
        -- Assume the object is a function
        return "function"
    end
end


--!
--! Collect signature.
--!
--! :param object:      The documentation object.
--! :param lines:       Lines in a file.
--! :param lineNumber:  Line to begin on.
--!
--! :returns: The line where the signature ends.
--!
local function CollectSignature(object, lines, lineNumber)
    -- The signature
    local signature = ""
    
    -- Count indentation characters on first line
    local indentSize = lines[lineNumber]:find("[^%s]") or 1
    
    if lines[lineNumber]:match("^%s*$") then
        -- The line following the docstring is empty, don't parse signature
        return lineNumber
    end
    
    -- Iterate over lines
    while lineNumber <= #lines do
        -- Current line
        local line = lines[lineNumber]
        
        -- Search for a '{' or a ';'
        local signatureEnd = line:find("%s*[{;]")
        
        if not signatureEnd then
            signature = signature .. line:sub(indentSize) .. "\n"
        else
            -- Hit the end of the signature
            signature = signature .. line:sub(indentSize, signatureEnd - 1)
            
            lineNumber = lineNumber + 1
            break
        end
        
        -- Go to the next line
        lineNumber = lineNumber + 1
    end
    
    -- Save the signature
    object.signatureFull = signature
    
    -- Get the object's type
    object.type = GetObjectType(signature)
    
    -- Strip the signature
    object.signature = StripSignature(signature)
    
    return lineNumber
end


--!
--! Get an object from the hierarchy by name.
--!
--! :param name:     Name to look for.
--! :param *parent:  Parent to look under.
--!
--! :returns: The found object, if any.
--!
local function GetObjectByName(name, parent)
    print("GetObjectByName(" .. tostring(name) .. ", " .. tostring(parent) .. ")")
    return nil
end


--!
--! Parse docstring commands.
--!
--! :param commands:  The command string to parse.
--! :param parent:    The current parent.
--!
--! :returns: #1 - The new parent.
--!           #2 - True, if the current object should become the new parent.
--!           #3 - True, if the docstring should be included as is (no signature).
--!
local function ParseDocstringCommands(commands, parent)
    print("Commands: ", commands)
    
    -- The new parent (defaults to current parent)
    local newParent = parent
    
    -- If true, the current object is the new parent
    local currentIsParent = false
    
    -- If true, the docstring is included as is
    local includeAsIs = false
    
    local i = 1
    while i <= #commands do
        -- Current character
        local char = commands:sub(i, i)
        
        if char == "~" then
            print("~ Include docstring as is")
            
            -- Include docstring as is (and don't collect signature)
            includeAsIs = true
            
            -- Reset new parent to current parent
            -- (it's not allowed to change the parent in the same docstring)
            newParent = parent
            
            break
        elseif char == ">" then
            print("> Current object will be new parent")
            
            -- Use the current object as the parent of all following objects
            currentIsParent = true
        elseif char == "<" then
            print("< Parent is parent's parent")
            
            -- Use the parent of the current object as the parent of all
            --  following objects
            newParent = newParent.parent
        elseif char == "^" then
            print("^ Reset parent")
            
            -- Use the root object as the parent of all following objects
            newParent = nil
        elseif char == "[" then
            -- Use the given object as the parent of all following objects
            
            -- Go to the next character
            i = i + 1
            
            -- Get the object's name
            local name = ""
            
            while i <= #commands do
                local nameChar = commands:sub(i, i)
                
                if nameChar ~= "]" then
                    name = name .. nameChar
                    i = i + 1
                else
                    i = i + 1
                    break
                end
            end
            
            newParent = GetObjectByName(name, newParent)
        end
        
        -- Go to the next character
        i = i + 1
    end
    
    return newParent, currentIsParent, includeAsIs
end


--!
--! Place the object into the hierarchy.
--!
--! :param object:         The object to place.
--! :param hierarchy:      The object hierarchy.
--! :param currentParent:  The current parent.
--!
local function PlaceObject(object, hierarchy, currentParent)
    
end


--!
--! Parse C++ file.
--!
--! :param file:       C++ source file to parse.
--! :param hierarchy:  The object hierarchy.
--!
function Cpp.ParseFile(file, hierarchy)
    -- Read the file into a table
    local lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    
    -- The current parent object (resets at the end of the file)
    local currentParent
    
    -- Iterate over lines
    local lineNumber = 1
    while lineNumber <= #lines do
        -- Current line
        local line = lines[lineNumber]
        
        --print(">", line)
        
        if IsDocstringBeginning(line) then
            -- Found the beginning of a docstring
            
            -- Create documentation object
            local object = {}
            
            -- Collect docstring:
            --  - object.docstringFull  (original docstring)
            --  - object.docstring      (stripped docstring, text only)
            --  - object.commands       (commands from the docstring)
            lineNumber = CollectDocstring(object, lines, lineNumber)
            
            -- Collect signature
            --  - object.signatureFull  (original signature)
            --  - object.signature      (stripped signature, what Sphinx wants)
            --  - object.type           (the object's type)
            lineNumber = CollectSignature(object, lines, lineNumber)
            
            print("OBJECT: ")
            for key, value in pairs(object) do
                print("\t", key)
                print(value)
                print()
            end
            print()
            
            -- Place the object (also parses docstring commands)
            PlaceObject(object, hierarchy, currentParent)
        else
            -- Go to next line
            lineNumber = lineNumber + 1
        end
    end
end


return Cpp
