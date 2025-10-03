local union = function(original,modification)
    for index,item in pairs(modification) do
        original[index] = item
    end
    return original
end

local default = function(original,modification)
    for index,item in pairs(modification) do
        if not original[index] then 
            original[index] = item
        end
    end
    return original
end

local callable = function(table,call)
    setmetatable(table,{__call = call})
end

--[[
{} literal parse entire thing if you can
() somehow pass information from one piece to another? so we would need storage
that would mean that () would need to be populated. let each () be an object therefore
a table with indices and items, a dictionary
so {set (name) of (dog) to ...} should... fix this.
]]

--[[
interesting question, how do i understand exactly what im doing? christ, we'll never figure out harp without neural. i think
it scares me a lot about the problem space of hm and many of the things in the world
most of the solutions are defined in the progression of time itself, a finite resource, that eventually leads to death.
we're optimising our programs to run faster, forgetting that we're actually buying ourselves more time, to live with them.
it's also interesting that the parser will read everything until finding an error, with faith that the next one will, not.
]]

local token = {}
token.__index = token
token.glue = "text"
token.object = "id"
token.literal = "text"
token.include = "text"
function token.new(type,properties)
    local new = {type = type}
    union(new,properties)
    setmetatable(new,token)
    return new
end
function token:isa(type)
    return type[self]
end

local text = {}
text.__index = text
function text.new(raw)
    local new = {
        raw = raw,
        cursor = 1
    }
    setmetatable(new,text)
    return new
end
function text:find(pattern)
    return string.find(self.raw,pattern,self.cursor,false)
end

local modes = {
    initial = {
        start = "%[",
        close = "%]"
    },
    literal = {
        start = "{",
        close = "}"
    },
    object = {
        start = "%(",
        close = "%)"
    },
    include = {
        start = "<",
        close = ">"
    }
}
callable(modes.initial,function(_,context,state)
    local statement = {parent = state.statement} -- dive into a deeper statement (and add one to the current one)
    table.insert(state.statement,statement)
    state.statement = statement
    while true do
        local next_close_start,next_close_end = state.text:find(modes.initial.close)
        local shortest,shortest_mode
        shortest = next_close_start
        for index,mode in pairs(modes) do
            local open_start,open_end = state.text:find(mode.start)
            if open_start then
                if (not shortest) or (open_end < shortest) then
                    shortest = open_end
                    shortest_mode = index
                end
            end
        end
        if not next_close_start then
            if statement.parent.parent then
                error("missing statement terminator",3)
            else
                break
            end
        elseif (shortest_mode) and (shortest < next_close_start) then
            local glue = state.text.raw:sub(state.text.cursor,shortest-1)
            if #glue > 0 then table.insert(statement,token.new(token.glue,{glue=glue})) end
            state.text.cursor = shortest+1
            context[shortest_mode](context,state)
        else
            state.text.cursor = next_close_end + 1
            break
        end
    end
    state.statement = state.statement.parent
end)
-- produces a mode function that only tries to find the end of itself and calls back a behaviour function to modify the statement
local function generic_mode_factory(name,callback)
    local mode = modes[name]
    callable(mode,function(_,context,state)
        local start = state.text.cursor
        while true do
            local next_open_start,next_open_end = state.text:find(mode.start)
            local next_close_start,next_close_end = state.text:find(mode.close)
            if next_close_start then
                if (next_open_start) and (next_open_start < next_close_start) then -- it opens again before it closes
                    state.text.cursor = next_close_end -- jump to the next close and try again
                else
                    state.text.cursor = next_close_end + 1
                    break -- get out and use this chunk
                end
            else
                error("idk missing end for "..name,3)
            end
        end
        callback(state,state.text.raw:gsub(start,state.text.cursor))
    end)
end
generic_mode_factory("literal",function(state,text)
    table.insert(state.statement,token.new(token.glue,{text=text}))
end)
generic_mode_factory("object",function(state,name)
    table.insert(state.statement,token.new(token.glue,{name=name}))
end)
generic_mode_factory("include",function(state,reference)
    table.insert(state.statement,token.new(token.glue,{reference=reference}))
end)

local context = {}
context.__index = context
function context:parse(raw)
    local state = {
        mode = "initial",
        statement = {parent = nil},
        text = text.new(raw),
        objects = {}
    }
    self.initial(self,state)
    local root = state.statement[1]
    return root
end
function context:evaluate(root)
    
end
union(context,modes)
function context.new(properties)
    properties = properties or {}
    local new = default(properties,{})
    setmetatable(new,context)
    return new
end

local context = context.new()
local arguments = {...}
for _,argument in pairs(arguments) do
    local file = io.open(argument,"r")
    if not file then error("Could not open "..argument) end
    local text = file:read("a")
    local root = context:parse(text)
    context:evaluate(root)
end