--!
--! HactDoc - C++ module
--! ====================
--!
--! This module implements C++ support for HactDoc.
--!


local Cpp = {}


--!
--! Split a string into a table of strings at given separator pattern.
--!
--! @param separator  The separator pattern (defaults to ".").
--!
--! @return The split string as a table of strings.
--!
function string:split(separator)
    local separator = separator or "."
    local fields = {}
    
    local pattern = string.format("([^%s]+)", separator)
    
    self:gsub(pattern,
        function(substring)
            fields[#fields + 1] = substring
        end
    )
    
    return fields
end


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
    local commandString = (firstLine:match("%[[^%]]*%]") or "")
    commandString = commandString .. (firstLine:match("[<>^~]+") or "")
    
    -- Save docstring command string
    object.commandString = commandString
    
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
    
    -- Save the short description (first line of stripped docstring)
    object.description = object.docstring:match("^[^\n]*")
    
    return lineNumber
end


--!
--! Strip a signature.
--!
--! :param signature:  The object's full signature.
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
    
    return signature
end


--!
--! Get object type based on signature.
--!
--! :param signature:  The object's full signature.
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
--! Get the first "word" in a string.
--!
--! :param signature:  The object's full signature.
--!
--! :returns: The first word.
--!
local function GetFirstWord(signature)
    -- The template level (number of nested "<>")
    local templateLevel = 0
    
    -- Iterate over characters
    local i = 1
    while i <= #signature do
        -- Current character
        local char = signature:sub(i, i)
        
        --print("char ", char)
        
        if templateLevel <= 0 and (char == ' '
                                   or char == '\t'
                                   or char == '\n') then
            -- Break character outside of template
            return signature:sub(1, i - 1)
        elseif char == "<" then
            -- Increase template level
            templateLevel = templateLevel + 1
        elseif char == ">" then
            -- Decrease template level
            templateLevel = templateLevel - 1
        end
        
        -- Go to the next character
        i = i + 1
    end
    
    -- Signature is single word only?
    return signature
end


--!
--! Parse identifier from signature.
--!
--! :param signature:  The object's full signature.
--!
--! :returns: The identifier.
--!
local function ParseIdentifier(signature)
    print("id ", signature)
    
    -- Strip whitespace at the beginning
    signature = signature:gsub("^%s*", "")
    
    if signature:match("^template") then
        -- Strip template (and the whitespace and line changes after it)
        signature = signature:gsub("^template%s+", "")
        signature = signature:sub(#GetFirstWord(signature) + 1, #signature)
    end
    
    print("id. ", signature)
    
    -- Find '('
    local bracketPosition = signature:find("%(")
    
    if bracketPosition then
        -- Strip everything after '(' (for functions)
        signature = signature:sub(1, bracketPosition - 1)
    end
    
    print("id. ", signature)
    
    -- Get the first "word"
    local firstWord = GetFirstWord(signature)
    
    print("id ", firstWord)
    
    if signature == firstWord then
        -- Special case: constructor or destructor
        -- (Do nothing)
    elseif firstWord:match("operator$") then
        -- Special case: `operator std::string` and similar
        -- (Do nothing)
        -- TODO: What exactly is the identifier here?
    else
        -- Strip first word
        signature = signature:sub(#firstWord + 1, #signature)
        
        -- Strip whitespace at the beginning
        signature = signature:gsub("^%s*", "")
    end
    
    print("id. ", signature)
    
    -- Get the identifier
    local identifier = GetFirstWord(signature)
    
    print("id ", identifier)
    
    -- Strip pointer or reference
    identifier = identifier:gsub("^[*&]", "")
    
    -- Return the identifier
    return identifier
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
        
        -- Search for constructor initialisation list
        local signatureEnd = line:find("%s*[^:]:[^:]")
        
        if not signatureEnd then
            -- Search for a '{' or a ';'
            signatureEnd = line:find("%s*[{;]")
        end
        
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
    
    -- Parse parent from signature
    object.identifierFull = ParseIdentifier(signature)
    
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
--! :param parent:  Parent to look under.
--!
--! :returns: The found object, if any.
--!
local function GetObjectByName(name, hierarchy, parent)
    print("GetObjectByName(" .. tostring(name) .. ", " .. tostring(parent) .. ")")
    
    -- Split the object name at '.'
    local nameParts = name:split(".")
    
    -- If parent is nil, start from the hierarchy root
    object = parent or hierarchy
    
    for _, namePart in ipairs(nameParts) do
        print("Looking for object `" .. name .. "`: \t" .. namePart)
        object = object[namePart]
        
        if not object then
            error("Undeclared identifier `" .. namePart .. "` in `" .. name .. "`", 2)
        end
    end
    
    return nil
end


--!
--! Parse docstring commands.
--!
--! :param commands:   The command string to parse.
--! :param hierarchy:  The object hierarchy.
--! :param parent:     The current parent.
--!
--! :returns: The parsed commands in a table.
--!
local function ParseDocstringCommands(commandString, hierarchy, parent)
    print("Commands: ", commandString)
    
    -- The parsed commands
    local commands = {
        -- Include the docstring as is (signature is ignored)
        includeAsIs = false;
        
        -- The new parent
        parent = parent;
        
        -- Make all following objects inherit the new parent
        inheritParent = false;
    }
    
    local i = 1
    while i <= #commandString do
        -- Current character
        local char = commandString:sub(i, i)
        
        if char == "~" then
            print("~ Include docstring as is")
            
            -- Include docstring as is (and don't collect signature)
            commands.includeAsIs = true
            
            -- Reset new parent to current parent
            -- (it's not allowed to change the parent in the same docstring)
            commands.parent = parent
            commands.inheritParent = false
            
            break
        elseif char == ">" then
            print("> Current object will be new parent")
            
            -- Use the current object as the parent of all following objects
            commands.inheritParent = true
        elseif char == "<" then
            print("< Parent is parent's parent")
            
            -- Use the parent of the current object as the parent of all
            --  following objects
            commands.parent = commands.parent and commands.parent.parent or nil
        elseif char == "^" then
            print("^ Reset parent")
            
            -- Use the root object as the parent of all following objects
            commands.parent = nil
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
            
            commands.parent = GetObjectByName(name, hierarchy, commands.parent)
        end
        
        -- Go to the next character
        i = i + 1
    end
    
    print("Commands:: ", commands.includeAsIs, commands.parent, commands.inheritParent)
    
    return commands
end


--!
--! Strip scopes from the identifier and signature.
--!
--! :param object:  The documentation object.
--!
local function StripScopes(object)
    object.identifier = object.identifierFull
    
    print("STRIP ", object.identifier, object.signature)
    
    -- Scopes to remove
    local removeScopes = {}
    
    -- The current parent
    local parent = object.parent
    
    while parent and parent.identifier do
        removeScopes[#removeScopes + 1] = parent.identifier .. "::"
        
        print("STRIP- ", removeScopes[#removeScopes])
        
        parent = parent.parent
    end
    
    -- Remove unnecessary scopes (start from root level)
    for i = #removeScopes, 1, -1 do
        local removeScope = removeScopes[i]
        
        object.identifier = object.identifier:gsub(removeScope, "")
        object.signature = object.signature:gsub(removeScope, "")
    end
    
    print("STRIP= ", object.identifier, object.signature)
end


--!
--! Place the object into the hierarchy.
--!
--! :param object:         The object to place.
--! :param hierarchy:      The object hierarchy.
--! :param currentParent:  The current parent.
--!
local function PlaceObject(object, hierarchy, currentParent)
    -- Parse docstring commands
    local commands = ParseDocstringCommands(object.commandString, hierarchy, currentParent)
    
    -- Save if the object should be included as is
    object.includeAsIs = commands.includeAsIs
    
    -- If parent is nil, use the hierarchy root
    local parent = commands.parent or hierarchy
    
    if object.identifierFull then
        -- Get the parent from the identifier
        local identifierParts = object.identifierFull:split("::")
        
        -- Remove the last part of the identifier (to get only the parents)
        identifierParts[#identifierParts] = nil
        
        for _, identifierPart in ipairs(identifierParts) do
            print("idPart ", identifierPart)
            
            if identifierPart == "" then
                -- Reset to hierarchy root
                parent = hierarchy
            else
                if identifierPart == "std" then
                    --break
                end
                
                parent = parent[identifierPart]
                
                if not parent then
                    error("Undeclared identifier `" .. identifierPart .. "` in `"
                          .. object.identifierFull .. "`"
                          .. " (" .. object.signatureFull .. ")")
                end
            end
        end
    end
    
    print("PARENT: ", parent.identifierFull)
    
    -- Save the object
    parent[#parent + 1] = object
    
    -- Save the parent into the object
    object.parent = parent
    
    if object.identifierFull then
        -- Strip scopes from the identifier and signature
        StripScopes(object)
    end
    
    print("SAVE: ", object.identifier, object.identifierFull)
    
    if object.identifier and object.type ~= "function" then
        -- Save the object by using the identifier as the key (for fast access)
        parent[object.identifier] = object
        
        parent = object
    end
    
    if commands.inheritParent then
        print("INHERIT PARENT")
        
        -- Inherit parent
        return parent
    else
        print("DON'T INHERIT PARENT")
        -- Don't inherit parent
        return currentParent
    end
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
            local object = {
                sourceFile = file;
            }
            
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
            currentParent = PlaceObject(object, hierarchy, currentParent)
        else
            -- Go to next line
            lineNumber = lineNumber + 1
        end
    end
end


return Cpp
