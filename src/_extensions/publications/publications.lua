function publications(args)
  local filepath = pandoc.utils.stringify(args[1])

  -- Read bibtex file.
  local f, err_msg = io.open(filepath, "r")
  if not f then
    error(err_msg)
  end
  local content = f:read("*all")
  f:close()
  bib = pandoc.read(content, "bibtex")

  -- Print out information from bibtex file for debugging.
  -- print("---")
  -- print("type(bib.meta.references[1])", type(bib.meta.references[1]))
  -- print("bib.meta.references[1].id", bib.meta.references[1].id)
  -- for key, value in pairs(bib.meta.references[1]) do
  --   print( key, type(value))  -- will print all keys
  -- end
  -- print("---")

  -- Create fake document with every bibtex entry cited.
  cite_list = {}
  for key, value in pairs(bib.meta.references) do
    c = pandoc.Citation(value.id, pandoc.NormalCitation)
    c2 = pandoc.Cite("hi", {c})
    p = pandoc.Para(c2)
    table.insert(cite_list, p)
  end
  cites = pandoc.BulletList(cite_list)

  cites_pd = pandoc.Pandoc({cites})
  cites_pd.meta.bibliography = filepath
  -- print("cites_pd", cites_pd)

  -- Generate references based on fake document.
  cites_pd_references = pandoc.utils.citeproc(cites_pd)
  -- print("cites_pd_references", cites_pd_references)
  -- print("---")
  -- for key, value in pairs(cites_pd_references.blocks) do
  --   print( key, type(value), value)  -- will print all keys
  -- end
  -- print("---")
  references_div = cites_pd_references.blocks[2]

  return references_div
end

return {
  publications = publications
}
