--!
--! HactDoc - C++ module
--! ====================
--!
--! This module implements C++ support for HactDoc.
--!


local Cpp = {}


--!
--! Strip C++ docstring.
--!
--! :param docstring:  Docstring to strip (single or multiple lines).
--!
--! :returns:  The stripped docstring.
--!
function Cpp.StripDocstring(docstring)
    --[[
    print("Docstring:")
    print("```")
    print(docstring)
    print("```")
    print()
    --]]
    
    local strippedDocstring = ""
    
    for line in docstring:gmatch("[^\r\n]+") do
        --print(">>", line)
        
        line = line:gsub("^%s*/%*%s?", "")
        line = line:gsub("^%s*%*/", "")
        line = line:gsub("^%s*%*%s?", "")
        
        strippedDocstring = strippedDocstring .. line .. "\n"
    end
    
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
--! Parse C++ file.
--!
--! :param file:  C++ source file to parse.
--!
function Cpp.ParseFile(file)
    local docstring = ""
    
    for line in io.lines(file) do
        print(">", line)
        
        if line:match("^%s*/%*!") or line:match("^%s*/%*%*") or line:match("^%s*%*") then
            docstring = docstring .. line .. "\n"
        end
        
        if line:match("%*/$") then
            Cpp.StripDocstring(docstring)
            docstring = ""
        end
    end
end


return Cpp

