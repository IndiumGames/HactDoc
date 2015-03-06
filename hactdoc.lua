--!
--! HactDoc
--! =======
--!
--! Extracts documentation from source code for Sphinx.
--!


local HactDoc = {
    Cpp = require("hactdoc_cpp");
    --Lua = {};
    
    objects = {};
}


--!
--! Parse a source file.
--!
--! :param file:  The source file to parse
--!
function HactDoc.ParseFile(file)
    print("*******************************************************************")
    print("Parsing file: ", file)
    print("===================================================================")
    
    if file:match("%.h$") or file:match("%.cpp$") then
        HactDoc.Cpp.ParseFile(file)
    elseif file:match("%.lua$") then
        print("Lua currently unsupported...")
    end
    
    print("*******************************************************************")
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
    
    for _, sourceFile in ipairs(sourceFiles) do
        HactDoc.ParseFile(sourceFile)
    end
    
    print("Saving output to directory: ", outputDir)
end


HactDoc.HactDoc{
    "../HactEngine/src/chronotime.h";
    "../HactEngine/src/chronotime.cpp";
}
