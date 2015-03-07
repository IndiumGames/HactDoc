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
--! Get an object from the hierarchy by name.
--!
--! :param name:     Name to look for.
--! :param *parent:  Parent to look under.
--!
--! :returns: The found object, if any.
--!
local function GetObjectByName(name, parent)
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
                local char = commands:sub(i, i)
                
                if char ~= "]" then
                    name = name .. char
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
--! Collects a docstring.
--!
--! :param lines:       Lines in a file.
--! :param lineNumber:  Line to begin on.
--!
--! :returns: #1 - The line where the docstring ends.
--!           #2 - The collected docstring.
--!
local function CollectDocstring(lines, lineNumber)
    -- First line of the docstring
    local firstLine = lines[lineNumber]
    
    -- Check for multiline comment
    local multilineComment = (firstLine:find("/%*!") or false)
    
    -- Get commands from the first line
    local commands = (firstLine:match("%[[^%]]*%]") or "")
    commands = commands .. (firstLine:match("[<>^~]+") or "")
    
    -- Parse docstring commands
    ParseDocstringCommands(commands)
    
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
                lineNumber = lineNumber + 1
                break
            end
        end
        
        -- Go to the next line
        lineNumber = lineNumber + 1
    end
    
    return lineNumber, docstring
end


--!
--! Strip the docstring.
--!
--! :param docstring:  Docstring to strip (single or multiple lines).
--!
--! :returns:  The stripped docstring.
--!
local function StripDocstring(docstring)
    --[[
    print("Docstring:")
    print("```")
    print(docstring)
    print("```")
    print()
    --]]
    
    --[[
    print(":vvv")
    print(docstring)
    print(":^^^")
    --]]
    
    -- Remove the docstring commands
    docstring = docstring:gsub("![^%s%*]*", "!", 1)
    
    --[[
    print("=vvv")
    print(docstring)
    print("=^^^")
    --]]
    
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
    
    --[[
    print("Stripped docstring:")
    print("```")
    print(strippedDocstring)
    print("```")
    print()
    --]]
    
    return strippedDocstring
end


--!
--! Collect signature.
--!
--! :param lines:       Lines in a file.
--! :param lineNumber:  Line to begin on.
--!
--! :returns: #1 - The line where the signature ends.
--!           #2 - The collected signature.
--!
local function CollectSignature(lines, lineNumber)
    -- The signature
    local signature = ""
    
    -- Count indentation characters on first line
    local indentSize = lines[lineNumber]:find("[^%s]") or 1
    
    -- Iterate over lines
    while lineNumber <= #lines do
        -- Current line
        local line = lines[lineNumber]
        
        -- Search for a '{' or a ';'
        local signatureEnd = line:find("%s*[{;]")
        
        if not signatureEnd then
            signature = signature .. line:sub(indentSize) .. " \\\n"
        else
            -- Hit the end of the signature
            signature = signature .. line:sub(indentSize, signatureEnd - 1)
            
            lineNumber = lineNumber + 1
            break
        end
        
        -- Go to the next line
        lineNumber = lineNumber + 1
    end
    
    --[[
    print("Signature:")
    print("```")
    print(signature)
    print("```")
    print()
    --]]
    
    return lineNumber, signature
end


--!
--! Parse C++ file.
--!
--! :param file:  C++ source file to parse.
--!
function Cpp.ParseFile(file)
    local docstring = nil
    local signature = nil
    
    -- Read the file into a table
    local lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    
    -- Iterate over lines
    local lineNumber = 1
    while lineNumber <= #lines do
        -- Current line
        local line = lines[lineNumber]
        
        --print(">", line)
        
        if IsDocstringBeginning(line) then
            --print("Docstring beginning at line: ", lineNumber)
            
            -- Found beginning of docstring, collect docstring
            lineNumber, docstring = CollectDocstring(lines, lineNumber)
            
            -- Save the full docstring
            --...
            
            -- Strip the docstring
            docstring = StripDocstring(docstring)
            
            -- Save the stripped docstring
            --...
            
            --print("Signature beginning at line:", lineNumber)
            
            -- Collect signature
            lineNumber, signature = CollectSignature(lines, lineNumber)
            
            -- Run docstring commands
            --...
        else
            -- Go to next line
            lineNumber = lineNumber + 1
        end
    end
end


return Cpp
