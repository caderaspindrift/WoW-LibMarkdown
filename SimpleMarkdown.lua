-- rewritten-from-scratch lightweight parser that only support very simple markdown

local  WOWWOWMARKDOWN10 = "LibWoWMarkdown-1.0";
local  WOWWOWMARKDOWN10_MINOR = 1;
if not LibStub then error(WOWMARKDOWN10 .. " requires LibStub."); end;
local  LWMD = LibStub:NewLibrary(WOWMARKDOWN10, WOWMARKDOWN10_MINOR);

LWMD.name  = WOWMARKDOWN10
LWMD.minor = WOWMARKDOWN10_MINOR;

LWMD.config = {
  [ 'rt1'             ] = '|TInterface\\TARGETINGFRAME\\UI-RAIDTARGETINGICON_1.PNG:0|t',
  [ 'rt2'             ] = '|TInterface\\TARGETINGFRAME\\UI-RAIDTARGETINGICON_2.PNG:0|t',
  [ 'rt3'             ] = '|TInterface\\TARGETINGFRAME\\UI-RAIDTARGETINGICON_3.PNG:0|t',
  [ 'rt4'             ] = '|TInterface\\TARGETINGFRAME\\UI-RAIDTARGETINGICON_4.PNG:0|t',
  [ 'rt5'             ] = '|TInterface\\TARGETINGFRAME\\UI-RAIDTARGETINGICON_5.PNG:0|t',
  [ 'rt6'             ] = '|TInterface\\TARGETINGFRAME\\UI-RAIDTARGETINGICON_6.PNG:0|t',
  [ 'rt7'             ] = '|TInterface\\TARGETINGFRAME\\UI-RAIDTARGETINGICON_7.PNG:0|t',
  [ 'rt8'             ] = '|TInterface\\TARGETINGFRAME\\UI-RAIDTARGETINGICON_8.PNG:0:|t',
  [ 'emsp'            ] = '|TInterface\\Store\\ServicesAtlas:0:0.75:0:0:1024:1024:1023:1024:1023:1024|t ',
  [ 'ensp'            ] = '|TInterface\\Store\\ServicesAtlas:0:0.25:0:0:1024:1024:1023:1024:1023:1024|t ',
  [ 'em13'            ] = '|TInterface\\Store\\ServicesAtlas:0:0.08:0:0:1024:1024:1023:1024:1023:1024|t ',
  [ 'em14'            ] = " ",
  [ 'nbsp'            ] = '|TInterface\\Store\\ServicesAtlas:0:0.175:0:0:1024:1024:1023:1024:1023:1024|t',
  [ 'thinsp'          ] = '|TInterface\\Store\\ServicesAtlas:0:0.100:0:0:1024:1024:1023:1024:1023:1024|t',
  [ 'strong'          ] = '|cff00dddd',
  ['/strong'          ] = '|r',
  [ 'em'              ] = '|cff00dd00',
  ['/em'              ] = '|r',
  [ 'ul'              ] = '<p>',
  ['/ul'              ] = '</p><br />',  -- it's almost always the right right choice to put <br /> after a block level tag
  [ 'ol'              ] = '<p>',
  ['/ol'              ] = '</p><br />',
  [ 'li'              ] = '',
  ['/li'              ] = '<br />',
  -- ['list_marker'      ] = '|TInterface\\MINIMAP\\TempleofKotmogu_ball_purple.PNG:0|t',
  ['list_marker'      ] = '*',
  [ 'pre'             ] = '<p>|cff66bbbb',
  ['/pre'             ] = '|r</p><br />',
  [ 'code'            ] = '|cff66bbbb',
  ['/code'            ] = '|r',
  ['br'               ] = '<br />',
  [ 'blockquote'      ] = '<hr width="100"/><p align="center">|cffbbbb00"',
  ['/blockquote'      ] = '"|r</p><br /><hr width="100"/><br />',
  [ 'blockquote_quot' ] = '',
  [ 'h1'              ] = '<h1>',
  ['/h1'              ] = '</h1><br />',
  [ 'h2'              ] = '<h2>',
  ['/h2'              ] = '</h2><br />',
  [ 'h3'              ] = '<h3>',
  ['/h3'              ] = '</h3><br />',
  [ 'p'               ] = '<p>',
  ['/p'               ] = '</p>',
  [ 'html'            ] = '<html>',
  ['/html'            ] = '</html>',
  [ 'body'            ] = '<body>',
  ['/body'            ] = '</body>',
  [ 'figcaption'      ] = 'Caption: |cffbbbb00',
  ['/figcaption'      ] = '|r',
}; -- beep

LWMD.entities_list = { "emsp", "ensp", "em13", "nbsp", "em14", "thinsp", };

LWMD.rt_list = { 
  rt1 = { "Star",           },
  rt2 = { "Circle", "Coin", },
  rt3 = { "Diamond",        },
  rt4 = { "Triangle",       },
  rt5 = { "Moon",           },
  rt6 = { "Square",         },
  rt7 = { "Cross", "X",     },
  rt8 = { "Skull",          }, 
};

function escape_text(text)
  text = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;");
  return text:gsub("|", "||");
end;

local function CreateNewParser()
  local Parser  = {};
  Parser.flags  = {};
  Parser.lines  = {};
  Parser.blocks = {};
  Parser.raw    = {};

  function Parser.GetBlock(       self , i ) return self.blocks[i]                          end;
  function Parser.GetLine(        self , i ) return self.lines[i]                           end;
  function Parser.GetRaw(         self , i ) return self.raw[i]                             end;
  function Parser.GetFirstBlock(  self     ) return self.blocks[1];                         end;
  function Parser.GetFirstLine(   self     ) return self.lines[1]                           end;
  function Parser.GetFirstRaw(    self     ) return self.raw[1]                             end;
  function Parser.GetLastBlock(   self     ) return self.blocks[#self.blocks]               end;
  function Parser.GetLastLine(    self     ) return self.lines[#self.lines]                 end;
  function Parser.GetLastRaw(     self     ) return self.raw[#self.raw]                     end;
  function Parser.YankFirstBlock( self     ) return table.remove(self.blocks, 1)            end;
  function Parser.YankFirstLine(  self     ) return table.remove(self.lines, 1)             end;
  function Parser.YankFirstRaw(   self     ) return table.remove(self.raw, 1);              end;
  function Parser.YankLastBlock(  self     ) return table.remove(self.blocks, #self.blocks) end;
  function Parser.YankLastLine(   self     ) return table.remove(self.lines, #self.lines)   end;
  function Parser.YankLastRaw(    self     ) return table.remove(self.raw, #self.raw);      end;

  function Parser.LoadRaw(self, data)
    local load_ok = true;
    for i, item in ipairs(data)
    do  if type(item) == "string" then table.insert(self.raw, item) else load_ok = false; end;
    end;
    return load_ok and self;
  end;

  function Parser.SetFlag(self, flag)
    self.flags[flag] = true;
    local coreFlag = flag:match("^(.+): ");
    if coreFlag then self.flags[coreFlag] = true; end;
    return self;
  end;

  function Parser.GetFlag(self, flag)
    if self.flags[flag] then return self.flags[flag] end;
    for currFlag, currFlagValue in pairs(self.flags)
    do  if string.match(currFlag, "^" .. flag .. ": ") then return currFlagValue end;
    end;
    return false;
  end;

  function Parser.ClearFlag(self, flag);
    self.flags[flag] = nil;
    local coreFlag = flag:match("^(.+): ");
    if   coreFlag then self.flags[coreFlag] = nil end;
    for  currFlag, _ in pairs(self.flags)
    do  if string.match(currFlag, "^" .. flag .. ": ")
           or (currFlag and string.match(currFlag, "^" .. coreFlag .. ": "))
        then self.flags[currFlag] = nil;
        end;
    end;
    return self;
  end;

  function Parser.ClearAllFlags(self)
    for k, _ in pairs(self.flags) do self.flags[k] = nil; end;
    return self;
  end;

  function Parser.CloseAllBlocks(self)
    for i, block in ipairs(self.blocks)
    do  block:Close();
    end;
  end;

  function Parser.NewLine(self, lineType)

    local Line =
    { lineType = lineType,
      parsed   = false,
      text     = "",
      html     = "",
      parser   = self,
    };

    function Line.SetText(self, value       ) self.text = value;              return self;         end;
    function Line.SetHtml(self, value       ) self.html = value;              return self;         end;
    function Line.SetTextParsed(self, value ) self.parsed = value;            return self;         end;
    function Line.SetType(self, value       ) self.lineType = value;          return self;         end;
    function Line.SetMatches(self, tab      ) self.matches = CopyTable(tab) ; return self          end;
    function Line.GetText(self              )                                 return self.text     end;
    function Line.GetHtml(self              )                                 return self.html     end;
    function Line.GetType(self              )                                 return self.lineType end;
    function Line.IsTextParsed(self         )                                 return self.parsed   end;
    function Line.GetMatches(self           )                                 return self.matches  end;
    function Line.GetParent(self            )                                 return self.parent   end;

    function Line.SetParent(self, parentBlock) 
      if parentBlock and parentBlock.children 
      then self.parent = parentBlock
           table.insert(parentBlock.children, self)
      end;
      return self;
    end;
           
    table.insert(self.lines, Line);

    return Line;
  end; -- beep

  function Parser.NewBlock(self, blockType)

    local Block =
    { children  = {},
      blockType = blockType,
      open      = true,
      parser    = self,
    };

    function Block.Close(self          ) self.open = false;      return self;          end ;
    -- ^^^ this is a placeholder

    function Block.IsClosed(self       )                         return not self.open  end ;
    function Block.IsOpen(self         )                         return self.open      end ;
    function Block.Open(self           ) self.open = true;       return self;          end ;
    function Block.SetType(self, value ) self.blockType = value; return self;          end ;
    function Block.GetType(self        )                         return self.blockType end ;

    function Block.AddChild(self, childLine)
      table.insert(self.children, childLine);
      childLine.parent = self;
      return self;
    end;

    function Block.NewLine(self, lineType)
      local line = self.parser:NewLine(lineType);
      self:AddChild(line);
      return line;
    end;

    function Block.CheckParsed(self)
      for i, line in ipairs(self.lines)
      do  if not line:IsTextParsed() then return false end;
      end;
      return true;
    end;

    return Block;
  end;

  return Parser;
end;

function Parser.thematic_break(self, text, matches)
  self:CloseAllBlocks();
  local block = self:NewBlock("thematic_break");
  local hr = block:NewLine("thematic_break");
  hr:SetText(text);
  hr:SetHtml("<hr />");
  hr:SetTextParsed(true);
  block:Close();
  return self;
end;

function Parser.start_code_fence(self, text, matches)
  self:CloseAllBlocks();
  local block = self:NewBlock("code_fence");
  local line = block:NewLine("code_fence_start");
  line:SetText(text);
  -- line:SetHtml("<pre>");
  line:SetHtml("");
  line:SetTextParsed(true);
  self:ClearAllFlags();
  self:SetFlag("code_fence: " .. matches[1]);
  return self;
end;
  
function Parser.continue_code_fence(self, text, matches)
  local line = self:GetLastBlock():NewLine("code");
  line:SetText(text);
  line:SetHtml(escape_text(text));
  line:SetTextParsed(true);
  return self;
end;

function Parser.stop_code_fence(self, text, matches)
  local currentBlock = self:GetLastBlock();
  local line = block:NewLine("code_fence_stop");
  line:SetText(text);
  -- line:SetHtml("</pre>");
  line:SetHtml("");
  line:SetTextParsed(true);
  self:ClearFlag("code_fence");
  return self;
end;
  
function Parser.atx_heading(self, text, matches)
  self:CloseAllBlocks();
  self:ClearAllFlags();
  local level = string.len(matches[1]);
  local block = self:NewBlock("atx_heading");
  local line = block:NewLine("atx_heading_" .. level);
  line:SetText(text);
  line:SetHtml(string.format("<h%i>%s</h%i>", level, matches[2], level));
  line:SetTextParsed(true);
  return self;
end;

function Parser.parse_line(self, line)
  local matches;
  local tests =  -- "pattern", "flags[: subflags]", "method" or function(self, line, matches)
  { { "^(```+)(.+)$", 
      "code_fence", 
      function(line, Parser, matches)
        if self:HasExactFlag("code_fence: " .. matches[1])
        then return self:stop_code_fence(line, matches);
        else return self:continue_code_fence(line, matches);
        end
      end },

    { "^(.+)$"                                      , "code_fence"      , "continue_code_fence"   },
    { "^ ? ? ?(```+)(.+)"                           , nil               , "start_code_fence"      },
    { "^ ? ? ?(=)==+%s*$"                           , "paragraph"       , "setext_heading"        },
    { "^ ? ? ?(%-)%-%-+%s*$"                        , "paragraph"       , "setext_heading"        },
    { "^ ? ? ?(%-)%-%-+%s*$"                        , nil               , "horizontal_rule"       },
    { "^ ? ? ?(=)==%s*$"                            , nil               , "horizontal_rule"       },
    { "^ ? ? ?(%*)%*%*+$"                           , nil               , "horizontal_rule"       },
    { "^ ? ? ?(#?#?#?#?#?#?)%s+(.+)$"               , nil               , "atx_heading"           },
    { "^ ? ? ?(%-)%s+(.+)$"                         , "list_bullet: -"  , "continue_list_bullet"  },
    { "^ ? ? ?(%-)%s+(.+)$"                         , nil               , "start_list_bullet"     },
    { "^ ? ? ?(%*)%s+(.+)$"                         , "list_bullet: *"  , "continue_list_bullet"  },
    { "^ ? ? ?(%*)%s+(.+)$"                         , nil               , "start_list_bullet"     },
    { "^ ? ? ?(%d)(%.)%s+(.+)$"                     , "list_ordered: ." , "continue_list_ordered" },
    { "^ ? ? ?(%d)(%.)%s+(.+)$"                     , nil               , "start_list_ordered"    },
    { "^ ? ? ?(.+)$"                                , "list_ordered"    , "continue_list_ordered" },
    { "^ ? ? ?(%d)(%))%s+(.+)$"                     , "list_ordered: )" , "continue_list_ordered" },
    { "^ ? ? ?(%d)(%))%s+(.+)$"                     , nil               , "start_list_ordered"    },
    { "^ ? ? ?(.+)$"                                , "list_ordered"    , "continue_list_ordered" },
    { "^    (.+)$"                                  , "code_indent"     , "continue_code_indent"  },
    { "^    (.+)$"                                  , nil               , "start_code_indent"     },
    { "^ ? ? ?%[(.-)%]:%s+(.-)%s*(.-)%s(.-)%s(.+)$" , nil               , "link_reference"        },

    { "^ ? ? ?(>+)%s+(.+)$", "blockquote", 
       function(self, line, matches)
         if self:HasExactFlag("blockquote: " .. matches[1])
         then return self:continue_blockquote(line, matches)
         else return self:start_blockquote(line, matches)
         end
       end, }

    { "^ ? ? ?(>+)%s+(.+)$" , nil          , "start_blockquote"    } ,
    { "^ ? ? ?(.+)%s+(.+)$" , "blockquote" , "continue_blockquote" } ,
    { "^ ? ? ?(.+)$"        , "paragraph"  , "continue_paragraph"  } ,
    { "^(%s*)$"             , nil          , "blank_line"          } ,
    { "^ ? ? ?(.+)$"        , nil          , "start_paragraph"     } ,

  };
  -- for (each test)
  --     if   (have flag) 
  --     then (try matches against pattern)
  --          if (matches)
  --          then if type(method) == "text"
  --               then self[method](self, text, matches);
  --               elseif type(method) == "function"
  --               then method(self, text, matches);
  -- at the end do cleanup, i.e. close any open blocks
  -- then return the parse
  --
  -- note to self: add methods on parser to actually return what it parsed, haha
  --
  -- the following needs to be:
  --
  -- (a) make parser or get an existing parser that we can use
  -- (b) load raw text into parser
  -- (c) parse the text
  -- (d) return the parsed text
  -- (e) done

end;

function LWMD.ToHTML(self, param)
     local ERRMESSAGE = "[" .. WOWMARKDOWN10 .. "]: " .. ":ToHTML() requires a string or list of strings.";
     local param_type = type(param);

     if     param_type == "string" 
     then   return self.config.html .. 
                     self.config.body .. 
                       self:markdown(param) ..
                     self.config["/body"] .. 
                   self.config["/html"];
     elseif param_type == "list"
            then local all_strings = true;

                 for _, item in ipairs(param)
                 do if type(item) ~= "string" then all_strings = true; break; end;
                 end;

                 if all_strings 
                 then return self.config.html .. 
                               self.config.body .. 
                                 self:markdown(param) ..
                               self.config["/body"] .. 
                             self.config["/html"];
                 else print(ERRMESSAGE);
                      return "";
                 end;
     else print(ERRMESSAGE);
          return "";
     end;
  end

function LWMD.ShowConfig(self)
    print("LMD.config = {");
    for k, v in pairs(self.config)
    do print(self.config.nbsp .. "['" .. k .. "'] = '" .. v .. "',");
    end;
    print("}");
  end;

LWMD.ToHtml = LWMD.ToHTML;
