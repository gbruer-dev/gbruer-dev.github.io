local function read_whole_file(filepath)
  local f, err_msg = io.open(filepath, "r")
  if not f then
    error(err_msg)
  end
  local content = f:read("*all")
  f:close()
  return content
end

local listings = {}
local latex_listings = {}

local function get_vars(meta)
  if meta.listing then
    for k, v in pairs(meta.listing) do
      if v.id then
        listings[pandoc.utils.stringify(v.id)] = v
      end
    end
  end
  if meta['latex-listing'] then
    for k, v in pairs(meta['latex-listing']) do
      if v.id then
        latex_listings[pandoc.utils.stringify(v.id)] = v
      end
    end
  end
end

local function latex_listing(el)
  if quarto.doc.is_format("html") then
    return
  end
  if listings[el.identifier] and latex_listings[el.identifier] then
    listing = listings[el.identifier]
    latex_listing = latex_listings[el.identifier]
    if latex_listing['latex-template'] then
      -- Read and parse latex template.
      template_path = pandoc.utils.stringify(latex_listing['latex-template'])
      template_str = read_whole_file(template_path)
      template = pandoc.template.compile(template_str)

      -- Get each entry in the listing.
      entries = {}
      for k,c in pairs(listing.contents) do
        -- Assume the contents are YAML files and parse the data.
        filepath = pandoc.utils.stringify(c)
        content = read_whole_file(filepath)
        content_doc = '---\nthings:\n' .. content .. '\n---'
        pd = pandoc.read(content_doc, "markdown")
        for k,v in ipairs(pd.meta.things) do
          entry = {}
          for i,f in ipairs(listing.fields) do
            field_str = pandoc.utils.stringify(f)
            entry[field_str] = pandoc.utils.stringify(v[field_str])
          end
          table.insert(entries, entry)
        end
      end

      -- Apply the template and parse the rendered template.
      context = {entries = entries}
      rendered_template = pandoc.template.apply(template, context)
      pd = pandoc.read(tostring(rendered_template), "latex")
      return pd.blocks
    end
  end
end

return {{Meta = get_vars}, {Div = latex_listing}}
